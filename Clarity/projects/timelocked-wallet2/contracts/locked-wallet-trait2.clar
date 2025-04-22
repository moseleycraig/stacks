
;; title: locked-wallet-trait2
;; version:
;; summary:
;; description: perform implementation of three functions when called

(define-trait locked-wallet-trait
    (
            (lock (principal uint unit) (response bool uint))
            (bestow (principal) (response bool uint))
            (claim (principal) (response bool uint))
    )
)