
;; title: counter
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;

;; data vars
;;

;; data maps
;;

(define-map counters principal uint)

;; read only functions
(define-read-only (get-count (who principal))
    (default-to u0 (map-get? counters who))
)

;; default-to will automatically unwrap
;; map-get returns either a "some" or "none"

;; public functions

;;(define-public (count-up)
;;    (begin
;;        (map-set counters tx-sender (+ (get-count tx-sender) u1))
;;        (ok true)
;;    )
;;)

(define-public (count-up)
    (ok (map-set counters tx-sender (+ (get-count tx-sender) u1)))
)

;; returns a boolean value
;; increment the counter and return true
;; avoid overflows (count too high)

;; private functions
;;

