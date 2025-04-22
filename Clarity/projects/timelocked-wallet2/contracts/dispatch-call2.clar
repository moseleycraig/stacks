;; title: dispatch-call2
;; version:
;; summary:
;; description: perform a dynamic dispatch

(use-trait locked-wallet-trait 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.locked-wallet-trait.')

(define-public (claim (wallet-contract <locked-wallet-trait>))
    (let (
        (beneficiary tx-sender)
    ) 
    (ok (try! (as-contract (contract-call? wallet-contract claim beneficiary)))) ;; contract passed as argument to func
    )
)

