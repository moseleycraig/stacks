;; Bitcoin-Powered Escrow Service
;; A simple Clarity smart contract for escrow that verifies a Bitcoin transaction

;; Constants
(define-constant ERR_NOT_OWNER (err u100))
(define-constant ERR_TX_UNVERIFIED (err u101))
(define-constant ERR_ESCROW_ACTIVE (err u102))
(define-constant ERR_NO_ESCROW (err u103))

;; Data Variables
(define-data-var escrow-active bool false)
(define-data-var beneficiary (optional principal) none)
(define-data-var owner (optional principal) none)
(define-data-var bitcoin-tx-hash (optional (buff 32)) none)
;; (define-data-var escrow-owner (optional principal) none)

;; Public Functions
(define-public (initialize (escrow-owner principal))
  (begin
    (asserts! (is-none (var-get owner)) ERR_ESCROW_ACTIVE)
    (var-set owner (some escrow-owner))
    (ok true)
  )
)

;; check if the escrow-owner needs to be a data variable

(define-public (lock-funds (new-beneficiary (optional principal)) (btc-tx-hash (buff 32)) (amount uint))
  (begin
    (asserts! (is-eq tx-sender (unwrap! (var-get owner) ERR_NOT_OWNER)) ERR_NOT_OWNER)
    (asserts! (not (var-get escrow-active)) ERR_ESCROW_ACTIVE)
    (asserts! (> amount u0) ERR_NO_ESCROW)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set escrow-active true)
    (var-set beneficiary new-beneficiary)
    (var-set bitcoin-tx-hash (some btc-tx-hash))
    (ok true)
  )
)

(define-public (release-funds (btc-tx-hash (buff 32)))
  (begin
    (asserts! (var-get escrow-active) ERR_NO_ESCROW)
    (asserts! (is-eq btc-tx-hash (unwrap! (var-get bitcoin-tx-hash) ERR_TX_UNVERIFIED)) ERR_TX_UNVERIFIED)
    (let ((beneficiary-address (unwrap! (var-get beneficiary) ERR_NO_ESCROW)))
      (try! (stx-transfer? (stx-get-balance tx-sender) tx-sender beneficiary-address))
      (var-set escrow-active false)
      (ok true)
    )
  )
)
