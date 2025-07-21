;; Bitcoin Oracle Storage Contract
;; Handles price feed data storage, historical data management, and oracle metadata

;; ===== CONSTANTS =====

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_INVALID_ASSET (err u201))
(define-constant ERR_INVALID_TIMESTAMP (err u202))
(define-constant ERR_DATA_NOT_FOUND (err u203))
(define-constant ERR_INVALID_RANGE (err u204))
(define-constant ERR_STORAGE_FULL (err u205))
(define-constant ERR_INVALID_CONFIDENCE (err u206))

;; Storage limits
(define-constant MAX_HISTORICAL_ENTRIES u1000) ;; Per asset
(define-constant MAX_ORACLE_METADATA_ENTRIES u100)
(define-constant MIN_CONFIDENCE_THRESHOLD u50) ;; 50%
(define-constant MAX_PRICE_AGE_BLOCKS u144) ;; ~24 hours

;; ===== DATA STRUCTURES =====

;; Current price feed data (most recent finalized prices)
(define-map current-price-feeds
  (string-ascii 10) ;; asset-id (BTC, ETH, USDC, STAX)
  {
    price: uint,
    confidence: uint,
    last-update-height: uint,
    last-update-timestamp: uint,
    bitcoin-anchor-block: (buff 32),
    validation-score: uint,
    is-finalized: bool,
    oracle-count: uint,
    deviation-score: uint, ;; How much oracles disagreed
    data-freshness: uint   ;; Blocks since last update
  }
)

;; Historical price data (time-series storage)
(define-map historical-prices
  { asset-id: (string-ascii 10), timestamp: uint }
  {
    price: uint,
    confidence: uint,
    block-height: uint,
    bitcoin-anchor-block: (buff 32),
    validation-score: uint,
    oracle-count: uint,
    deviation-score: uint
  }
)

;; Price feed metadata and statistics
(define-map price-feed-metadata
  (string-ascii 10) ;; asset-id
  {
    total-updates: uint,
    first-update-timestamp: uint,
    last-update-timestamp: uint,
    average-confidence: uint,
    max-price: uint,
    min-price: uint,
    price-volatility: uint, ;; Simplified volatility measure
    is-active: bool,
    supported-since-height: uint
  }
)

;; Oracle performance metrics
(define-map oracle-performance
  { oracle: principal, asset-id: (string-ascii 10) }
  {
    total-submissions: uint,
    accurate-submissions: uint,
    last-submission-height: uint,
    average-deviation: uint, ;; How far off from consensus
    uptime-score: uint, ;; Percentage of rounds participated
    response-time-score: uint, ;; How quickly oracle responds
    reputation-trend: uint ;; Improving/declining reputation
  }
)

;; Historical confidence scores tracking
(define-map confidence-history
  { asset-id: (string-ascii 10), height: uint }
  {
    confidence: uint,
    oracle-count: uint,
    consensus-strength: uint, ;; How much oracles agreed
    timestamp: uint
  }
)

;; Asset configuration and status
(define-map asset-registry
  (string-ascii 10) ;; asset-id
  {
    is-active: bool,
    precision: uint, ;; Decimal places
    min-price: uint, ;; Sanity check minimum
    max-price: uint, ;; Sanity check maximum
    update-frequency: uint, ;; Expected update frequency in blocks
    description: (string-ascii 50),
    added-at-height: uint
  }
)

;; ===== DATA VARIABLES =====

(define-data-var authorized-core-contract (optional principal) none)
(define-data-var total-assets uint u0)
(define-data-var total-price-updates uint u0)
(define-data-var storage-version uint u1)

;; Historical data pagination
(define-data-var historical-data-index uint u0)

;; ===== PRIVATE FUNCTIONS =====

;; Calculate price volatility (simplified)
(define-private (calculate-volatility (asset-id (string-ascii 10)) (new-price uint))
  (match (map-get? price-feed-metadata asset-id)
    metadata 
      (let (
        (max-price (max (get max-price metadata) new-price))
        (min-price (min (get min-price metadata) new-price))
        (price-range (if (> max-price u0) (/ (* (- max-price min-price) u10000) max-price) u0))
      )
        price-range ;; Return volatility as basis points
      )
    u0 ;; No existing data
  )
)

;; Update metadata statistics
(define-private (update-metadata-stats (asset-id (string-ascii 10)) (price uint) (confidence uint))
  (let (
    (existing-metadata (default-to 
      { total-updates: u0, first-update-timestamp: u0, last-update-timestamp: u0,
        average-confidence: u0, max-price: u0, min-price: u999999999999999999,
        price-volatility: u0, is-active: true, supported-since-height: stacks-block-height }
      (map-get? price-feed-metadata asset-id)))
    (new-total (+ (get total-updates existing-metadata) u1))
    (new-avg-confidence (/ (+ (* (get average-confidence existing-metadata) (get total-updates existing-metadata)) confidence) new-total))
    (current-time (unwrap! (get-stacks-block-info? time stacks-block-height) u0))
  )
    (map-set price-feed-metadata asset-id
      {
        total-updates: new-total,
        first-update-timestamp: (if (is-eq (get total-updates existing-metadata) u0) current-time (get first-update-timestamp existing-metadata)),
        last-update-timestamp: current-time,
        average-confidence: new-avg-confidence,
        max-price: (max (get max-price existing-metadata) price),
        min-price: (min (get min-price existing-metadata) price),
        price-volatility: (calculate-volatility asset-id price),
        is-active: true,
        supported-since-height: (get supported-since-height existing-metadata)
      }
    )
    true
  )
)

;; Clean old historical data (keep only recent entries)
(define-private (cleanup-historical-data (asset-id (string-ascii 10)))
  ;; Simplified cleanup - in production would remove oldest entries
  ;; when approaching MAX_HISTORICAL_ENTRIES limit
  true
)

;; Validate asset ID format
(define-private (is-valid-asset-id (asset-id (string-ascii 10)))
  (and
    (> (len asset-id) u0)
    (<= (len asset-id) u10)
    ;; Additional validation could check against whitelist
    true
  )
)

;; ===== AUTHORIZATION =====

;; Set authorized core contract (only owner can call)
(define-public (set-core-contract (core-contract principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set authorized-core-contract (some core-contract))
    (ok true)
  )
)

;; Check if caller is authorized core contract
(define-private (is-authorized-core)
  (match (var-get authorized-core-contract)
    core-contract (is-eq tx-sender core-contract)
    false
  )
)

;; ===== PUBLIC FUNCTIONS - WRITE OPERATIONS =====

;; Store current price feed data (called by core contract)
(define-public (store-price-feed 
  (asset-id (string-ascii 10))
  (price uint)
  (confidence uint)
  (bitcoin-anchor-block (buff 32))
  (validation-score uint)
  (oracle-count uint)
  (deviation-score uint))
  
  (let (
    (current-height stacks-block-height)
    (current-time (unwrap! (get-stacks-block-info? time current-height) ERR_INVALID_TIMESTAMP))
    (data-freshness u0) ;; Just updated, so freshness is 0
  )
    ;; Only authorized core contract can store data
    (asserts! (is-authorized-core) ERR_UNAUTHORIZED)
    (asserts! (is-valid-asset-id asset-id) ERR_INVALID_ASSET)
    (asserts! (>= confidence MIN_CONFIDENCE_THRESHOLD) ERR_INVALID_CONFIDENCE)
    (asserts! (> price u0) ERR_INVALID_RANGE)
    
    ;; Store current price feed
    (map-set current-price-feeds asset-id
      {
        price: price,
        confidence: confidence,
        last-update-height: current-height,
        last-update-timestamp: current-time,
        bitcoin-anchor-block: bitcoin-anchor-block,
        validation-score: validation-score,
        is-finalized: true,
        oracle-count: oracle-count,
        deviation-score: deviation-score,
        data-freshness: data-freshness
      }
    )
    
    ;; Store historical entry
    (map-set historical-prices
      { asset-id: asset-id, timestamp: current-time }
      {
        price: price,
        confidence: confidence,
        block-height: current-height,
        bitcoin-anchor-block: bitcoin-anchor-block,
        validation-score: validation-score,
        oracle-count: oracle-count,
        deviation-score: deviation-score
      }
    )
    
    ;; Store confidence tracking
    (map-set confidence-history
      { asset-id: asset-id, height: current-height }
      {
        confidence: confidence,
        oracle-count: oracle-count,
        consensus-strength: (- u100 deviation-score), ;; Inverse of deviation
        timestamp: current-time
      }
    )
    
    ;; Update metadata
    (try! (update-metadata-stats asset-id price confidence))
    
    ;; Clean up old data if needed
    (cleanup-historical-data asset-id)
    
    ;; Update global counters
    (var-set total-price-updates (+ (var-get total-price-updates) u1))
    
    (ok true)
  )
)

;; Store oracle performance data
(define-public (store-oracle-performance
  (oracle principal)
  (asset-id (string-ascii 10))
  (was-accurate bool)
  (deviation uint)
  (response-time-score uint))
  
  (let (
    (existing-perf (default-to
      { total-submissions: u0, accurate-submissions: u0, last-submission-height: u0,
        average-deviation: u0, uptime-score: u100, response-time-score: u100, reputation-trend: u100 }
      (map-get? oracle-performance { oracle: oracle, asset-id: asset-id })))
    (new-total (+ (get total-submissions existing-perf) u1))
    (new-accurate (if was-accurate (+ (get accurate-submissions existing-perf) u1) (get accurate-submissions existing-perf)))
    (new-avg-deviation (/ (+ (* (get average-deviation existing-perf) (get total-submissions existing-perf)) deviation) new-total))
    (accuracy-rate (if (> new-total u0) (/ (* new-accurate u100) new-total) u0))
  )
    ;; Only authorized core contract can store data
    (asserts! (is-authorized-core) ERR_UNAUTHORIZED)
    (asserts! (is-valid-asset-id asset-id) ERR_INVALID_ASSET)
    
    (map-set oracle-performance { oracle: oracle, asset-id: asset-id }
      {
        total-submissions: new-total,
        accurate-submissions: new-accurate,
        last-submission-height: stacks-block-height,
        average-deviation: new-avg-deviation,
        uptime-score: accuracy-rate, ;; Simplified uptime based on accuracy
        response-time-score: response-time-score,
        reputation-trend: accuracy-rate ;; Simplified trend = current accuracy
      }
    )
    (ok true)
  )
)

;; Register new asset for tracking
(define-public (register-asset
  (asset-id (string-ascii 10))
  (precision uint)
  (min-price uint)
  (max-price uint)
  (update-frequency uint)
  (description (string-ascii 50)))
  
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-valid-asset-id asset-id) ERR_INVALID_ASSET)
    (asserts! (< min-price max-price) ERR_INVALID_RANGE)
    
    (map-set asset-registry asset-id
      {
        is-active: true,
        precision: precision,
        min-price: min-price,
        max-price: max-price,
        update-frequency: update-frequency,
        description: description,
        added-at-height: stacks-block-height
      }
    )
    
    (var-set total-assets (+ (var-get total-assets) u1))
    (ok true)
  )
)

;; ===== READ-ONLY FUNCTIONS =====

;; Get current price feed
(define-read-only (get-current-price-feed (asset-id (string-ascii 10)))
  (map-get? current-price-feeds asset-id)
)

;; Get price at specific timestamp
(define-read-only (get-historical-price (asset-id (string-ascii 10)) (timestamp uint))
  (map-get? historical-prices { asset-id: asset-id, timestamp: timestamp })
)

;; Get asset metadata and statistics
(define-read-only (get-asset-metadata (asset-id (string-ascii 10)))
  (map-get? price-feed-metadata asset-id)
)

;; Get oracle performance for specific asset
(define-read-only (get-oracle-performance (oracle principal) (asset-id (string-ascii 10)))
  (map-get? oracle-performance { oracle: oracle, asset-id: asset-id })
)

;; Get confidence history at specific height
(define-read-only (get-confidence-at-height (asset-id (string-ascii 10)) (height uint))
  (map-get? confidence-history { asset-id: asset-id, height: height })
)

;; Get asset configuration
(define-read-only (get-asset-config (asset-id (string-ascii 10)))
  (map-get? asset-registry asset-id)
)

;; Check if price data is fresh
(define-read-only (is-price-fresh (asset-id (string-ascii 10)))
  (match (map-get? current-price-feeds asset-id)
    price-feed
      (let (
        (blocks-since-update (- stacks-block-height (get last-update-height price-feed)))
      )
        (<= blocks-since-update MAX_PRICE_AGE_BLOCKS)
      )
    false
  )
)

;; Get price feed summary for all assets
(define-read-only (get-all-current-prices)
  {
    btc: (map-get? current-price-feeds "BTC"),
    eth: (map-get? current-price-feeds "ETH"),
    usdc: (map-get? current-price-feeds "USDC"),
    stax: (map-get? current-price-feeds "STAX")
  }
)

;; Get oracle performance summary
(define-read-only (get-oracle-summary (oracle principal))
  {
    btc-performance: (map-get? oracle-performance { oracle: oracle, asset-id: "BTC" }),
    eth-performance: (map-get? oracle-performance { oracle: oracle, asset-id: "ETH" }),
    usdc-performance: (map-get? oracle-performance { oracle: oracle, asset-id: "USDC" }),
    stax-performance: (map-get? oracle-performance { oracle: oracle, asset-id: "STAX" })
  }
)

;; Get system storage statistics
(define-read-only (get-storage-stats)
  {
    total-assets: (var-get total-assets),
    total-price-updates: (var-get total-price-updates),
    storage-version: (var-get storage-version),
    authorized-core: (var-get authorized-core-contract)
  }
)

;; Health check for storage system
(define-read-only (get-storage-health)
  {
    is-authorized: (is-some (var-get authorized-core-contract)),
    total-assets: (var-get total-assets),
    total-updates: (var-get total-price-updates),
    btc-is-fresh: (is-price-fresh "BTC"),
    eth-is-fresh: (is-price-fresh "ETH"),
    usdc-is-fresh: (is-price-fresh "USDC"),
    stax-is-fresh: (is-price-fresh "STAX")
  }
)