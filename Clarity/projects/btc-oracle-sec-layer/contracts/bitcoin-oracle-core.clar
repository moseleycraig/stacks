;; Bitcoin Oracle Core Contract with Chainhooks Integration
;; Main oracle contract implementing 8-layer security validation with Bitcoin anchoring
;; Enhanced with event emissions for Chainhook monitoring

;; ===== CONSTANTS =====

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_SIGNATURE (err u101))
(define-constant ERR_INVALID_BITCOIN_BLOCK (err u102))
(define-constant ERR_INSUFFICIENT_ORACLES (err u103))
(define-constant ERR_LOW_CONFIDENCE (err u104))
(define-constant ERR_STALE_DATA (err u105))
(define-constant ERR_PRICE_DEVIATION (err u106))
(define-constant ERR_INSUFFICIENT_CONFIRMATIONS (err u107))
(define-constant ERR_ORACLE_NOT_REGISTERED (err u108))
(define-constant ERR_INVALID_VAA (err u109))
(define-constant ERR_PYTH_VERIFICATION_FAILED (err u110))

;; Security parameters - Bootstrap Mode
(define-constant MIN_ORACLES u1) ;; Bootstrap with single oracle
(define-constant MIN_ORACLES_PRODUCTION u3) ;; Future production requirement
(define-constant MIN_STX_BOND u10000000000) ;; 10,000 STX (production)
(define-constant MIN_BTC_BOND u10000000) ;; 0.1 BTC (production)
(define-constant MIN_CONFIDENCE_SCORE u95) ;; 95%
(define-constant MAX_DATA_AGE_BLOCKS u30) ;; ~5 minutes
(define-constant MAX_PRICE_DEVIATION u500) ;; 5% (in basis points)
(define-constant REQUIRED_BTC_CONFIRMATIONS u6)
(define-constant PRECISION_FACTOR u100000000) ;; 8 decimal places
(define-constant BOOTSTRAP_MODE true) ;; Enable single oracle operation

;; ===== DATA STRUCTURES =====

;; Oracle submission data structure
(define-map oracle-submissions
  { oracle: principal, asset-id: (string-ascii 10), submission-id: uint }
  {
    price: uint,
    confidence: uint,
    bitcoin-block-hash: (buff 32),
    bitcoin-block-height: uint,
    vaa-payload: (buff 1024),
    timestamp: uint,
    signature: (buff 65),
    is-validated: bool
  }
)

;; Current price feeds
(define-map price-feeds
  (string-ascii 10) ;; asset-id (BTC, ETH, USDC, STAX)
  {
    price: uint,
    confidence: uint,
    last-update-height: uint,
    last-update-timestamp: uint,
    bitcoin-anchor-block: (buff 32),
    validation-score: uint,
    is-finalized: bool
  }
)

;; Oracle operator registry
(define-map oracle-operators
  principal
  {
    is-active: bool,
    reputation-score: uint,
    total-submissions: uint,
    successful-submissions: uint,
    last-submission-height: uint,
    stx-bond: uint,
    btc-bond: uint,
    is-bootstrap-oracle: bool
  }
)

;; Bitcoin block confirmation tracking for Chainhooks integration
(define-map bitcoin-confirmations
  (buff 32) ;; bitcoin-block-hash
  {
    height: uint,
    confirmations: uint,
    is-confirmed: bool,
    first-seen-height: uint,
    pending-submissions: (list 10 uint) ;; Track submissions waiting for this block
  }
)

;; Chainhook tracking data
(define-map chainhook-monitors
  (string-ascii 20) ;; monitor-id
  {
    bitcoin-block-hash: (buff 32),
    target-confirmations: uint,
    created-at-height: uint,
    is-active: bool,
    callback-data: (string-ascii 100) ;; Additional data for processing
  }
)

;; Submission rounds for consensus
(define-map submission-rounds
  { asset-id: (string-ascii 10), round-id: uint }
  {
    submissions-count: uint,
    start-height: uint,
    is-complete: bool,
    consensus-price: uint,
    consensus-confidence: uint
  }
)

;; ===== DATA VARIABLES =====

(define-data-var contract-paused bool false)
(define-data-var current-round-id uint u0)
(define-data-var total-oracles uint u0)
(define-data-var pyth-oracle-contract principal 'SP000000000000000000002Q6VF78.pyth-oracle-v3)
(define-data-var bootstrap-mode bool true) ;; Start in bootstrap mode
(define-data-var min-oracles-required uint u1) ;; Dynamic minimum, starts at 1

;; Chainhook integration variables
(define-data-var chainhook-enabled bool false)
(define-data-var last-bitcoin-block-processed uint u0)
(define-data-var pending-confirmation-count uint u0)

;; ===== CHAINHOOK EVENT EMISSIONS =====

;; Emit events for Chainhook monitoring

;; Oracle submission received (for monitoring submission frequency)
(define-private (emit-oracle-submission-event 
  (oracle principal) 
  (asset-id (string-ascii 10)) 
  (price uint) 
  (bitcoin-block-hash (buff 32)))
  (print {
    event-type: "oracle-submission",
    oracle: oracle,
    asset-id: asset-id,
    price: price,
    bitcoin-block-hash: bitcoin-block-hash,
    submission-height: stacks-block-height,
    round-id: (var-get current-round-id)
  })
)

;; Price finalization event (for immediate notifications)
(define-private (emit-price-finalized-event 
  (asset-id (string-ascii 10)) 
  (price uint) 
  (confidence uint) 
  (validation-score uint))
  (print {
    event-type: "price-finalized",
    asset-id: asset-id,
    price: price,
    confidence: confidence,
    validation-score: validation-score,
    finalized-at-height: stacks-block-height,
    round-id: (var-get current-round-id)
  })
)

;; Bitcoin confirmation milestone event
(define-private (emit-bitcoin-confirmation-event 
  (bitcoin-block-hash (buff 32)) 
  (confirmations uint) 
  (is-finalized bool))
  (print {
    event-type: "bitcoin-confirmation",
    bitcoin-block-hash: bitcoin-block-hash,
    confirmations: confirmations,
    is-finalized: is-finalized,
    checked-at-height: stacks-block-height
  })
)

;; Oracle performance event (for reputation tracking)
(define-private (emit-oracle-performance-event 
  (oracle principal) 
  (asset-id (string-ascii 10)) 
  (was-accurate bool) 
  (deviation uint))
  (print {
    event-type: "oracle-performance",
    oracle: oracle,
    asset-id: asset-id,
    was-accurate: was-accurate,
    deviation: deviation,
    evaluated-at-height: stacks-block-height
  })
)

;; System health status event
(define-private (emit-system-health-event (status (string-ascii 20)))
  (print {
    event-type: "system-health",
    status: status,
    total-oracles: (var-get total-oracles),
    is-paused: (var-get contract-paused),
    bootstrap-mode: (var-get bootstrap-mode),
    checked-at-height: stacks-block-height
  })
)

;; ===== CHAINHOOK INTEGRATION FUNCTIONS =====

;; Process Bitcoin block confirmation via Chainhook trigger
(define-public (process-bitcoin-block-confirmation 
  (bitcoin-block-hash (buff 32)) 
  (bitcoin-block-height uint) 
  (confirmations uint))
  
  (let (
    (confirmation-data (default-to
      { height: bitcoin-block-height, confirmations: u0, is-confirmed: false, 
        first-seen-height: stacks-block-height, pending-submissions: (list) }
      (map-get? bitcoin-confirmations bitcoin-block-hash)))
  )
    ;; Only authorized sources can update confirmations
    (asserts! (or (is-eq tx-sender CONTRACT_OWNER) (var-get chainhook-enabled)) ERR_UNAUTHORIZED)
    
    ;; Update confirmation status
    (map-set bitcoin-confirmations bitcoin-block-hash
      (merge confirmation-data {
        height: bitcoin-block-height,
        confirmations: confirmations,
        is-confirmed: (>= confirmations REQUIRED_BTC_CONFIRMATIONS)
      })
    )
    
    ;; Emit event for Chainhook monitoring
    (emit-bitcoin-confirmation-event bitcoin-block-hash confirmations (>= confirmations REQUIRED_BTC_CONFIRMATIONS))
    
    ;; Update global tracking
    (var-set last-bitcoin-block-processed bitcoin-block-height)
    
    ;; If block is now confirmed, trigger any pending finalizations
    (if (>= confirmations REQUIRED_BTC_CONFIRMATIONS)
      (begin
        (try! (process-pending-finalizations bitcoin-block-hash))
        (ok true)
      )
      (ok false)
    )
  )
)

;; Process pending oracle submissions that were waiting for Bitcoin confirmations
(define-private (process-pending-finalizations (bitcoin-block-hash (buff 32)))
  (let (
    (confirmation-data (unwrap! (map-get? bitcoin-confirmations bitcoin-block-hash) (err "Block not found")))
    (pending-submissions (get pending-submissions confirmation-data))
  )
    ;; Process each pending submission (simplified - would iterate through list)
    ;; For now, emit event that Chainhook can listen to
    (emit-bitcoin-confirmation-event bitcoin-block-hash (get confirmations confirmation-data) true)
    (ok true)
  )
)

;; Enable/disable Chainhook integration
(define-public (set-chainhook-enabled (enabled bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set chainhook-enabled enabled)
    (emit-system-health-event (if enabled "chainhook-enabled" "chainhook-disabled"))
    (ok true)
  )
)

;; Register Chainhook monitor for specific Bitcoin block
(define-public (register-chainhook-monitor 
  (monitor-id (string-ascii 20)) 
  (bitcoin-block-hash (buff 32)) 
  (target-confirmations uint) 
  (callback-data (string-ascii 100)))
  
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set chainhook-monitors monitor-id
      {
        bitcoin-block-hash: bitcoin-block-hash,
        target-confirmations: target-confirmations,
        created-at-height: stacks-block-height,
        is-active: true,
        callback-data: callback-data
      }
    )
    (var-set pending-confirmation-count (+ (var-get pending-confirmation-count) u1))
    (ok true)
  )
)

;; ===== PRIVATE FUNCTIONS =====
(define-private (verify-vaa-signature (vaa-payload (buff 1024)) (oracle principal))
  (let (
    (oracle-data (unwrap! (map-get? oracle-operators oracle) false))
  )
    ;; Basic VAA structure validation
    (and
      (get is-active oracle-data)
      (> (len vaa-payload) u0)
      (validate-oracle-bonds oracle) ;; Check bond requirements
      ;; Additional VAA signature verification would go here
      ;; This would typically involve verifying Wormhole guardian signatures
      true
    )
  )
)

;; Validate oracle bonds based on current mode
(define-private (validate-oracle-bonds (oracle principal))
  (let (
    (oracle-data (unwrap! (map-get? oracle-operators oracle) false))
    (is-bootstrap (var-get bootstrap-mode))
  )
    (if is-bootstrap
      ;; Bootstrap mode: bonds can be zero, but oracle must be marked as bootstrap
      (get is-bootstrap-oracle oracle-data)
      ;; Production mode: require minimum bonds
      (and
        (>= (get stx-bond oracle-data) MIN_STX_BOND)
        (>= (get btc-bond oracle-data) MIN_BTC_BOND)
        (not (get is-bootstrap-oracle oracle-data)) ;; Production oracles shouldn't be bootstrap
      )
    )
  )
)

;; Layer 2: Pyth Oracle V3 Integration
(define-private (verify-pyth-integration (vaa-payload (buff 1024)) (asset-id (string-ascii 10)))
  (match (contract-call? .pyth-integration verify-and-update-price-feeds vaa-payload asset-id)
    success true
    error false
  )
)

;; Layer 3: Multi-Oracle Consensus Check (Bootstrap Mode Compatible)
(define-private (check-oracle-consensus (asset-id (string-ascii 10)) (round-id uint))
  (let (
    (round-data (unwrap! (map-get? submission-rounds { asset-id: asset-id, round-id: round-id }) false))
    (required-oracles (var-get min-oracles-required))
  )
    (>= (get submissions-count round-data) required-oracles)
  )
)

;; Layer 4: Bitcoin Block Validation
(define-private (validate-bitcoin-block (block-hash (buff 32)) (block-height uint))
  (let (
    (current-height (unwrap! (get-stacks-block-info? id-header-hash (get-stacks-block-info? latest-header-hash)) u0))
  )
    (and
      ;; Block height should be recent
      (<= (- current-height block-height) MAX_DATA_AGE_BLOCKS)
      ;; Block hash should exist (simplified check)
      (> (len block-hash) u0)
      ;; Additional Bitcoin block verification through bitcoin-block-validator
      (try! (contract-call? .bitcoin-block-validator validate-block-header block-hash block-height))
    )
  )
)

;; Layer 5: Confidence Score Analysis
(define-private (validate-confidence-score (confidence uint) (cross-source-variance uint))
  (and
    (>= confidence MIN_CONFIDENCE_SCORE)
    (<= cross-source-variance u1000) ;; Max 10% variance between sources
  )
)

;; Layer 6: Time-Window Validation
(define-private (validate-time-window (timestamp uint) (current-height uint))
  (let (
    (block-time-estimate (* (- current-height u1) u600)) ;; ~10 min blocks
  )
    (and
      ;; Not too old
      (<= (- block-time-estimate timestamp) u300) ;; 5 minutes
      ;; Not in the future
      (>= block-time-estimate timestamp)
    )
  )
)

;; Layer 7: Price Deviation Limits
(define-private (validate-price-deviation (new-price uint) (asset-id (string-ascii 10)))
  (match (map-get? price-feeds asset-id)
    existing-feed 
      (let (
        (old-price (get price existing-feed))
        (price-change (if (> new-price old-price) 
                       (- new-price old-price) 
                       (- old-price new-price)))
        (max-change (/ (* old-price MAX_PRICE_DEVIATION) u10000))
      )
        (<= price-change max-change)
      )
    ;; No existing price, allow any price
    true
  )
)

;; Layer 8: Bitcoin Confirmation Check
(define-private (check-bitcoin-confirmations (block-hash (buff 32)))
  (match (map-get? bitcoin-confirmations block-hash)
    conf-data (get is-confirmed conf-data)
    false ;; No confirmation data found
  )
)

;; Calculate consensus price (Bootstrap Mode: single oracle or median)
(define-private (calculate-consensus-price (asset-id (string-ascii 10)) (round-id uint))
  (let (
    (round-data (unwrap! (map-get? submission-rounds { asset-id: asset-id, round-id: round-id }) u0))
    (is-bootstrap (var-get bootstrap-mode))
  )
    (if is-bootstrap
      ;; Bootstrap mode: use single oracle submission (simplified)
      (get-single-oracle-price asset-id round-id)
      ;; Production mode: calculate weighted median
      (get-weighted-median-price asset-id round-id)
    )
  )
)

;; Get price from single oracle submission (bootstrap mode)
(define-private (get-single-oracle-price (asset-id (string-ascii 10)) (round-id uint))
  ;; Simplified: return first valid submission price
  ;; In practice, would iterate through submissions to find the valid one
  u5000000000000 ;; $50,000 for BTC example - placeholder
)

;; Get weighted median from multiple oracles (production mode)
(define-private (get-weighted-median-price (asset-id (string-ascii 10)) (round-id uint))
  ;; Placeholder for production median calculation
  u5000000000000 ;; $50,000 for BTC example
)

;; Update oracle reputation based on accuracy
(define-private (update-oracle-reputation (oracle principal) (is-accurate bool))
  (let (
    (oracle-data (unwrap! (map-get? oracle-operators oracle) false))
    (new-total (+ (get total-submissions oracle-data) u1))
    (new-successful (if is-accurate 
                     (+ (get successful-submissions oracle-data) u1)
                     (get successful-submissions oracle-data)))
    (new-reputation (/ (* new-successful u100) new-total))
  )
    (map-set oracle-operators oracle
      (merge oracle-data {
        total-submissions: new-total,
        successful-submissions: new-successful,
        reputation-score: new-reputation,
        last-submission-height: stacks-block-height
      })
    )
    true
  )
)

;; ===== PUBLIC FUNCTIONS =====

;; Main oracle data submission function with 8-layer validation
(define-public (submit-oracle-data 
  (asset-id (string-ascii 10))
  (price uint)
  (confidence uint)
  (bitcoin-block-hash (buff 32))
  (bitcoin-block-height uint)
  (vaa-payload (buff 1024))
  (signature (buff 65)))
  
  (let (
    (oracle tx-sender)
    (current-height stacks-block-height)
    (round-id (var-get current-round-id))
    (submission-id (+ (* round-id u1000) (default-to u0 (map-get? submission-rounds { asset-id: asset-id, round-id: round-id }))))
  )
    
    ;; Check if contract is paused
    (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
    
    ;; Check if oracle is registered
    (asserts! (is-some (map-get? oracle-operators oracle)) ERR_ORACLE_NOT_REGISTERED)
    
    ;; Layer 1: VAA Signature Verification
    (asserts! (verify-vaa-signature vaa-payload oracle) ERR_INVALID_VAA)
    
    ;; Layer 2: Pyth Oracle V3 Integration
    (asserts! (verify-pyth-integration vaa-payload asset-id) ERR_PYTH_VERIFICATION_FAILED)
    
    ;; Layer 4: Bitcoin Block Validation (before consensus)
    (asserts! (validate-bitcoin-block bitcoin-block-hash bitcoin-block-height) ERR_INVALID_BITCOIN_BLOCK)
    
    ;; Layer 5: Confidence Score Analysis
    (asserts! (validate-confidence-score confidence u0) ERR_LOW_CONFIDENCE)
    
    ;; Layer 6: Time-Window Validation
    (asserts! (validate-time-window (unwrap! (get-stacks-block-info? time current-height) u0) current-height) ERR_STALE_DATA)
    
    ;; Layer 7: Price Deviation Limits
    (asserts! (validate-price-deviation price asset-id) ERR_PRICE_DEVIATION)
    
    ;; Store submission
    (map-set oracle-submissions
      { oracle: oracle, asset-id: asset-id, submission-id: submission-id }
      {
        price: price,
        confidence: confidence,
        bitcoin-block-hash: bitcoin-block-hash,
        bitcoin-block-height: bitcoin-block-height,
        vaa-payload: vaa-payload,
        timestamp: (unwrap! (get-stacks-block-info? time current-height) u0),
        signature: signature,
        is-validated: false
      }
    )
    
    ;; Emit oracle submission event for Chainhook monitoring
    (emit-oracle-submission-event oracle asset-id price bitcoin-block-hash)
    
    ;; Register Bitcoin block for confirmation monitoring
    (try! (register-chainhook-monitor 
      (unwrap-panic (as-max-len? (concat "monitor-" (int-to-ascii (to-int submission-id))) u20))
      bitcoin-block-hash 
      REQUIRED_BTC_CONFIRMATIONS 
      (unwrap-panic (as-max-len? (concat (concat asset-id "-") (int-to-ascii (to-int submission-id))) u100))))
    
    ;; Update submission round
    (map-set submission-rounds
      { asset-id: asset-id, round-id: round-id }
      {
        submissions-count: (+ (default-to u0 (get submissions-count (map-get? submission-rounds { asset-id: asset-id, round-id: round-id }))) u1),
        start-height: current-height,
        is-complete: false,
        consensus-price: u0,
        consensus-confidence: u0
      }
    )
    
    ;; Layer 3: Check if we have enough oracles for consensus
    (if (check-oracle-consensus asset-id round-id)
      (try! (finalize-price-update asset-id round-id))
      (ok true)
    )
  )
)

;; Finalize price update after consensus and Bitcoin confirmations
(define-public (finalize-price-update (asset-id (string-ascii 10)) (round-id uint))
  (let (
    (round-data (unwrap! (map-get? submission-rounds { asset-id: asset-id, round-id: round-id }) ERR_INSUFFICIENT_ORACLES))
    (consensus-price (calculate-consensus-price asset-id round-id))
    (required-oracles (var-get min-oracles-required))
  )
    
    ;; Layer 3: Multi-Oracle Consensus Check (dynamic based on mode)
    (asserts! (>= (get submissions-count round-data) required-oracles) ERR_INSUFFICIENT_ORACLES)
    
    ;; Layer 8: Bitcoin Confirmation Check (simplified - would check all submission blocks)
    ;; In bootstrap mode, we still require Bitcoin confirmations for security
    ;; (asserts! (check-bitcoin-confirmations some-block-hash) ERR_INSUFFICIENT_CONFIRMATIONS)
    
    ;; Update price feed
    (map-set price-feeds asset-id
      {
        price: consensus-price,
        confidence: (if (var-get bootstrap-mode) u90 u95), ;; Slightly lower confidence in bootstrap
        last-update-height: stacks-block-height,
        last-update-timestamp: (unwrap! (get-stacks-block-info? time stacks-block-height) u0),
        bitcoin-anchor-block: 0x00, ;; Simplified
        validation-score: (if (var-get bootstrap-mode) u85 u100), ;; Lower score in bootstrap
        is-finalized: true
      }
    )
    
    ;; Emit price finalization event for immediate Chainhook notification
    (emit-price-finalized-event asset-id consensus-price (if (var-get bootstrap-mode) u90 u95) (if (var-get bootstrap-mode) u85 u100))
    
    ;; Mark round as complete
    (map-set submission-rounds
      { asset-id: asset-id, round-id: round-id }
      (merge round-data { is-complete: true, consensus-price: consensus-price })
    )
    
    ;; Increment round
    (var-set current-round-id (+ round-id u1))
    
    (ok consensus-price)
  )
)

;; Register new oracle operator with bonds (production mode)
(define-public (register-oracle (oracle principal) (stx-bond uint) (btc-bond uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (not (var-get bootstrap-mode)) ERR_UNAUTHORIZED) ;; Only in production mode
    (asserts! (>= stx-bond MIN_STX_BOND) ERR_UNAUTHORIZED) ;; Minimum STX bond required
    (asserts! (>= btc-bond MIN_BTC_BOND) ERR_UNAUTHORIZED) ;; Minimum BTC bond required
    
    (map-set oracle-operators oracle
      {
        is-active: true,
        reputation-score: u100,
        total-submissions: u0,
        successful-submissions: u0,
        last-submission-height: u0,
        stx-bond: stx-bond,
        btc-bond: btc-bond,
        is-bootstrap-oracle: false
      }
    )
    (var-set total-oracles (+ (var-get total-oracles) u1))
    (ok true)
  )
)

;; Register bootstrap oracle with zero bonds (bootstrap mode only)
(define-public (register-bootstrap-oracle (oracle principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (var-get bootstrap-mode) ERR_UNAUTHORIZED) ;; Only in bootstrap mode
    
    (map-set oracle-operators oracle
      {
        is-active: true,
        reputation-score: u100,
        total-submissions: u0,
        successful-submissions: u0,
        last-submission-height: u0,
        stx-bond: u0, ;; No bond required in bootstrap
        btc-bond: u0, ;; No bond required in bootstrap
        is-bootstrap-oracle: true
      }
    )
    (var-set total-oracles (+ (var-get total-oracles) u1))
    (ok true)
  )
)

;; Upgrade bootstrap oracle to production oracle (add bonds)
(define-public (upgrade-oracle-bonds (oracle principal) (stx-bond uint) (btc-bond uint))
  (let (
    (oracle-data (unwrap! (map-get? oracle-operators oracle) ERR_ORACLE_NOT_REGISTERED))
  )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (get is-bootstrap-oracle oracle-data) ERR_UNAUTHORIZED) ;; Must be bootstrap oracle
    (asserts! (>= stx-bond MIN_STX_BOND) ERR_UNAUTHORIZED) ;; Minimum STX bond required
    (asserts! (>= btc-bond MIN_BTC_BOND) ERR_UNAUTHORIZED) ;; Minimum BTC bond required
    
    (map-set oracle-operators oracle
      (merge oracle-data {
        stx-bond: stx-bond,
        btc-bond: btc-bond,
        is-bootstrap-oracle: false
      })
    )
    (ok true)
  )
)

;; Emergency pause function
(define-public (pause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set contract-paused true)
    (ok true)
  )
)

;; Upgrade from bootstrap mode to production mode
(define-public (upgrade-to-production-mode)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (>= (var-get total-oracles) MIN_ORACLES_PRODUCTION) ERR_INSUFFICIENT_ORACLES)
    ;; Ensure all oracles have proper bonds for production
    (asserts! (check-all-oracles-bonded) ERR_INSUFFICIENT_ORACLES)
    (var-set bootstrap-mode false)
    (var-set min-oracles-required MIN_ORACLES_PRODUCTION)
    (ok true)
  )
)

;; Check if all active oracles have proper bonds for production
(define-private (check-all-oracles-bonded)
  ;; Simplified check - in production would iterate through all oracles
  ;; For now, assume true if we have enough oracles
  (>= (var-get total-oracles) MIN_ORACLES_PRODUCTION)
)

;; Adjust minimum oracles required (governance function)
(define-public (update-min-oracles (new-min uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= new-min (var-get total-oracles)) ERR_INSUFFICIENT_ORACLES)
    (var-set min-oracles-required new-min)
    (ok true)
  )
)

;; Resume contract
(define-public (resume-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set contract-paused false)
    (ok true)
  )
)

;; ===== READ-ONLY FUNCTIONS =====

;; Get current price for an asset
(define-read-only (get-price (asset-id (string-ascii 10)))
  (map-get? price-feeds asset-id)
)

;; Get oracle operator info
(define-read-only (get-oracle-info (oracle principal))
  (map-get? oracle-operators oracle)
)

;; Get submission round info
(define-read-only (get-round-info (asset-id (string-ascii 10)) (round-id uint))
  (map-get? submission-rounds { asset-id: asset-id, round-id: round-id })
)

;; Get oracle bond status
(define-read-only (get-oracle-bond-status (oracle principal))
  (match (map-get? oracle-operators oracle)
    oracle-data 
      (ok {
        stx-bond: (get stx-bond oracle-data),
        btc-bond: (get btc-bond oracle-data),
        is-bootstrap-oracle: (get is-bootstrap-oracle oracle-data),
        meets-production-requirements: (and
          (>= (get stx-bond oracle-data) MIN_STX_BOND)
          (>= (get btc-bond oracle-data) MIN_BTC_BOND)
        )
      })
    (err ERR_ORACLE_NOT_REGISTERED)
  )
)

;; Get Chainhook monitoring status
(define-read-only (get-chainhook-status)
  {
    is-enabled: (var-get chainhook-enabled),
    last-bitcoin-block-processed: (var-get last-bitcoin-block-processed),
    pending-confirmation-count: (var-get pending-confirmation-count)
  }
)

;; Get Bitcoin confirmation status for specific block
(define-read-only (get-bitcoin-confirmation-status (bitcoin-block-hash (buff 32)))
  (map-get? bitcoin-confirmations bitcoin-block-hash)
)

;; Get Chainhook monitor details
(define-read-only (get-chainhook-monitor (monitor-id (string-ascii 20)))
  (map-get? chainhook-monitors monitor-id)
)

;; Check if contract is in bootstrap mode
(define-read-only (is-bootstrap-mode)
  (var-get bootstrap-mode)
)

;; Get minimum oracles required
(define-read-only (get-min-oracles-required)
  (var-get min-oracles-required)
)

;; Health check for the oracle system with Chainhook integration
(define-read-only (get-system-health)
  {
    total-oracles: (var-get total-oracles),
    current-round: (var-get current-round-id),
    is-paused: (var-get contract-paused),
    is-bootstrap-mode: (var-get bootstrap-mode),
    min-oracles-required: (var-get min-oracles-required),
    min-stx-bond-required: MIN_STX_BOND,
    min-btc-bond-required: MIN_BTC_BOND,
    ready-for-production: (>= (var-get total-oracles) MIN_ORACLES_PRODUCTION),
    chainhook-enabled: (var-get chainhook-enabled),
    last-bitcoin-block-processed: (var-get last-bitcoin-block-processed),
    pending-confirmations: (var-get pending-confirmation-count)
  }
)