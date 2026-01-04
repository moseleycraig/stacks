;; ===== CONSTANTS =====

(define-constant CONTRACT_OWNER tx-sender)

;; Authorization Errors (100-199)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_CONTRACT_OWNER (err u101))
(define-constant ERR_NOT_ORACLE (err u102))
(define-constant ERR_NOT_PROTOCOL_OWNER (err u103))
(define-constant ERR_NOT_ADMIN (err u104))
(define-constant ERR_ORACLE_NOT_REGISTERED (err u105))
(define-constant ERR_INSUFFICIENT_PERMISSIONS (err u106))

;; Validation Errors (200-299)
(define-constant ERR_INVALID_SCORE (err u200))
(define-constant ERR_INVALID_PROTOCOL_ADDRESS (err u201))
(define-constant ERR_INVALID_THRESHOLD (err u202))
(define-constant ERR_INVALID_TIMESTAMP (err u203))
(define-constant ERR_INVALID_PERCENTAGE (err u204))
(define-constant ERR_INVALID_TVL (err u205))
(define-constant ERR_INVALID_BLOCK_HEIGHT (err u206))
(define-constant ERR_INVALID_GRADE (err u207))
(define-constant ERR_INVALID_METRIC_VALUE (err u208))
(define-constant ERR_EMPTY_STRING (err u209))
(define-constant ERR_STRING_TOO_LONG (err u210))
(define-constant ERR_INVALID_URL (err u211))
(define-constant ERR_INVALID_EMAIL (err u212))

;; State Errors (300-399)
(define-constant ERR_PROTOCOL_ALREADY_EXISTS (err u300))
(define-constant ERR_PROTOCOL_NOT_FOUND (err u301))
(define-constant ERR_ALERT_ALREADY_EXISTS (err u302))
(define-constant ERR_ALERT_NOT_FOUND (err u303))
(define-constant ERR_SCORE_NOT_FOUND (err u304))
(define-constant ERR_HISTORICAL_DATA_NOT_FOUND (err u305))
(define-constant ERR_PROTOCOL_PAUSED (err u306))
(define-constant ERR_SYSTEM_PAUSED (err u307))
(define-constant ERR_ORACLE_ALREADY_REGISTERED (err u308))
(define-constant ERR_NO_DATA_AVAILABLE (err u309))

;; Data/Threshold Errors (400-499)
(define-constant ERR_SCORE_BELOW_MINIMUM (err u400))
(define-constant ERR_SCORE_STALE (err u401))
(define-constant ERR_INSUFFICIENT_HISTORY (err u402))
(define-constant ERR_TVL_DROP_CRITICAL (err u403))
(define-constant ERR_MAX_ALERTS_REACHED (err u404))
(define-constant ERR_DUPLICATE_SCORE_SUBMISSION (err u405))
(define-constant ERR_SCORE_DEVIATION_TOO_HIGH (err u406))
(define-constant ERR_DATA_INTEGRITY_FAILURE (err u407))
(define-constant ERR_CONFLICTING_DATA (err u408))

;; System/Configuration Errors (500-599)
(define-constant ERR_CONTRACT_NOT_INITIALIZED (err u500))
(define-constant ERR_ALREADY_INITIALIZED (err u501))
(define-constant ERR_UPGRADE_IN_PROGRESS (err u502))
(define-constant ERR_MIGRATION_REQUIRED (err u503))
(define-constant ERR_MAX_PROTOCOLS_REACHED (err u504))
(define-constant ERR_RATE_LIMIT_EXCEEDED (err u505))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u506))
(define-constant ERR_FEATURE_NOT_ENABLED (err u507))
(define-constant ERR_ORACLE_SYNC_FAILED (err u508))
(define-constant ERR_BITCOIN_ANCHOR_FAILED (err u509))

;; Configuration Constants
(define-constant MAX_PROTOCOLS u100)
(define-constant MAX_ALERTS_PER_USER u10)
(define-constant SCORE_STALENESS_THRESHOLD u144)
(define-constant MAX_SCORE_DEVIATION u50)
(define-constant MINIMUM_SCORE_THRESHOLD u0)
(define-constant MAXIMUM_SCORE_THRESHOLD u100)

;; Scoring Weight Constants
(define-constant WEIGHT_SECURITY u40)
(define-constant WEIGHT_LIQUIDITY u25)
(define-constant WEIGHT_DECENTRALIZATION u20)
(define-constant WEIGHT_OPERATIONAL u15)

;; Grade Thresholds
(define-constant GRADE_A_THRESHOLD u90)
(define-constant GRADE_B_THRESHOLD u80)
(define-constant GRADE_C_THRESHOLD u70)
(define-constant GRADE_D_THRESHOLD u60)

;; String Constants for Grades
(define-constant GRADE_A "A")
(define-constant GRADE_B "B")
(define-constant GRADE_C "C")
(define-constant GRADE_D "D")
(define-constant GRADE_F "F")

;; ===== DATA VARIABLES =====

(define-data-var contract-initialized bool false)
(define-data-var total-protocols uint u0)
(define-data-var contract-paused bool false)
(define-data-var score-update-interval uint u144)

;; ===== DATA MAPS =====

;; Protocol Registry - Basic protocol information
(define-map protocol-registry
    { protocol-address: principal }
    {
        name: (string-ascii 64),
        is-active: bool,
        date-registered: uint,
        owner: principal,
        category: (string-ascii 32)
    }
)

;; Protocol Scores - Current health scores and grades
(define-map protocol-scores
    { protocol-address: principal }
    {
        total-score: uint,
        grade: (string-ascii 1),
        security-score: uint,
        liquidity-score: uint,
        decentralization-score: uint,
        operational-score: uint,
        last-updated: uint,
        block-height: uint
    }
)

;; Historical Scores - Time-series score data
(define-map historical-scores
    { 
        protocol-address: principal,
        timestamp: uint
    }
    {
        total-score: uint,
        grade: (string-ascii 1),
        block-height: uint
    }
)

;; Security Metrics - Detailed security breakdown
(define-map security-metrics
    { protocol-address: principal }
    {
        audit-status: bool,
        audit-score: uint,
        admin-keys-score: uint,
        time-locks-score: uint,
        bug-bounty-score: uint,
        upgradeability-score: uint,
        total-security-score: uint
    }
)

;; Liquidity Metrics - Detailed liquidity breakdown
(define-map liquidity-metrics
    { protocol-address: principal }
    {
        tvl: uint,
        tvl-score: uint,
        depth-score: uint,
        volume-score: uint,
        volatility-score: uint,
        exit-capacity-score: uint,
        total-liquidity-score: uint
    }
)

;; Decentralization Metrics - Detailed decentralization breakdown
(define-map decentralization-metrics
    { protocol-address: principal }
    {
        whale-concentration-score: uint,
        governance-score: uint,
        oracle-score: uint,
        user-base-score: uint,
        transparency-score: uint,
        total-decentralization-score: uint
    }
)

;; Operational Metrics - Detailed operational breakdown
(define-map operational-metrics
    { protocol-address: principal }
    {
        uptime-score: uint,
        incidents-score: uint,
        age-score: uint,
        documentation-score: uint,
        total-operational-score: uint
    }
)

;; User Alerts - User-configured alert settings
(define-map user-alerts
    {
        user: principal,
        protocol-address: principal
    }
    {
        threshold: uint,
        alert-type: (string-ascii 16),
        is-active: bool,
        last-triggered: uint
    }
)

;; User Alert Count - Track number of alerts per user
(define-map user-alert-count
    { user: principal }
    { count: uint }
)

;; Registered Oracles - Authorized data providers
(define-map registered-oracles
    { oracle-address: principal }
    {
        is-active: bool,
        registration-block: uint,
        reputation-score: uint,
        total-submissions: uint
    }
)

;; Protocol Pause Status - Emergency pause per protocol
(define-map protocol-pause-status
    { protocol-address: principal }
    {
        is-paused: bool,
        paused-at: uint,
        paused-by: principal,
        reason: (string-ascii 128)
    }
)

;; ===== PRIVATE HELPER FUNCTIONS =====

;; Authorization Helpers

(define-private (is-contract-owner (caller principal))
    (is-eq caller CONTRACT_OWNER)
)

(define-private (is-registered-oracle (caller principal))
    (match (map-get? registered-oracles { oracle-address: caller })
        oracle (get is-active oracle)
        false
    )
)

(define-private (is-protocol-owner (caller principal) (protocol principal))
    (match (map-get? protocol-registry { protocol-address: protocol })
        registry (is-eq caller (get owner registry))
        false
    )
)

;; Validation Helpers

(define-private (is-valid-score (score uint))
    (and 
        (>= score MINIMUM_SCORE_THRESHOLD)
        (<= score MAXIMUM_SCORE_THRESHOLD)
    )
)

(define-private (is-valid-percentage (value uint))
    (and (>= value u0) (<= value u100))
)

(define-private (protocol-exists (protocol principal))
    (is-some (map-get? protocol-registry { protocol-address: protocol }))
)

(define-private (is-protocol-active (protocol principal))
    (match (map-get? protocol-registry { protocol-address: protocol })
        registry (get is-active registry)
        false
    )
)

(define-private (is-score-stale (last-update uint))
    (> (- stacks-block-height last-update) SCORE_STALENESS_THRESHOLD)
)

(define-private (is-string-valid (str (string-ascii 64)) (max-len uint))
    (and 
        (> (len str) u0)
        (<= (len str) max-len)
    )
)

(define-private (is-system-paused)
    (var-get contract-paused)
)

(define-private (is-protocol-paused (protocol principal))
    (match (map-get? protocol-pause-status { protocol-address: protocol })
        status (get is-paused status)
        false
    )
)

;; Calculation Helpers

(define-private (calculate-total-score 
    (security uint)
    (liquidity uint)
    (decentralization uint)
    (operational uint))
    (+
        (/ (* security WEIGHT_SECURITY) u100)
        (+ (/ (* liquidity WEIGHT_LIQUIDITY) u100)
            (+ (/ (* decentralization WEIGHT_DECENTRALIZATION) u100)
                (/ (* operational WEIGHT_OPERATIONAL) u100)
            )
        )
    )
)

(define-private (calculate-weighted-score (score uint) (weight uint))
    (/ (* score weight) u100)
)

;; Grade Assignment Helpers

(define-private (score-to-grade (score uint))
    (if (>= score GRADE_A_THRESHOLD)
        GRADE_A
        (if (>= score GRADE_B_THRESHOLD)
            GRADE_B
            (if (>= score GRADE_C_THRESHOLD)
                GRADE_C
                (if (>= score GRADE_D_THRESHOLD)
                    GRADE_D
                    GRADE_F
                )
            )
        )
    )
)

(define-private (is-grade-critical (grade (string-ascii 1)))
    (or (is-eq grade GRADE_D) (is-eq grade GRADE_F))
)

;; Security Score Calculation

(define-private (calculate-security-score
    (audit uint)
    (admin-keys uint)
    (time-locks uint)
    (bug-bounty uint)
    (upgradeability uint))
    (+ audit (+ admin-keys (+ time-locks (+ bug-bounty upgradeability))))
)

;; Liquidity Score Calculation

(define-private (calculate-liquidity-score
    (tvl-score uint)
    (depth uint)
    (volume uint)
    (volatility uint)
    (exit-capacity uint))
    (+ tvl-score (+ depth (+ volume (+ volatility exit-capacity))))
)

;; Decentralization Score Calculation

(define-private (calculate-decentralization-score
    (whale uint)
    (governance uint)
    (oracle uint)
    (user-base uint)
    (transparency uint))
    (+ whale (+ governance (+ oracle (+ user-base transparency))))
)

;; Operational Score Calculation

(define-private (calculate-operational-score
    (uptime uint)
    (incidents uint)
    (age uint)
    (documentation uint))
    (+ uptime (+ incidents (+ age documentation)))
)

;; Alert Helpers

(define-private (should-trigger-alert (current-score uint) (threshold uint))
    (< current-score threshold)
)

(define-private (get-user-alert-count (user principal))
    (default-to 
        u0
        (get count (map-get? user-alert-count { user: user }))
    )
)

(define-private (has-max-alerts (user principal))
    (>= (get-user-alert-count user) MAX_ALERTS_PER_USER)
)

;; Data Retrieval Helpers

(define-private (get-protocol-score (protocol principal))
    (map-get? protocol-scores { protocol-address: protocol })
)

(define-private (get-protocol-info (protocol principal))
    (map-get? protocol-registry { protocol-address: protocol })
)

;; Score Deviation Check

(define-private (is-score-deviation-acceptable 
    (old-score uint) 
    (new-score uint))
    (let
        (
            (difference (if (> new-score old-score)
                (- new-score old-score)
                (- old-score new-score)
            ))
        )
        (<= difference MAX_SCORE_DEVIATION)
    )
)

;; Timestamp Validation

(define-private (is-valid-timestamp (timestamp uint))
    (and (> timestamp u0) (<= timestamp stacks-block-height))
)

;; Protocol Count Check

(define-private (has-max-protocols)
    (>= (var-get total-protocols) MAX_PROTOCOLS)
)
