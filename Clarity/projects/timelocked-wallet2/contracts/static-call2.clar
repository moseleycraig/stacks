
;; title: static-call2
;; version:
;; summary:
;; description: perform a static dispatch

(define-public (func) 
    (begin 
        (ok (try! (as-contract (contract-call? contract-principal func arg1))))
    )
)