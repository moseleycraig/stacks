;; Block post
;; contarct writing a post on chain for a small fee
;; on chain data co$t$

;; start with immutable contracts
;; common start is the contract owner

(define-constant contract-owner (as-contract tx-sender)) ;; tx-sender = contract deployer
;; as-contract fx change tx-sender from standard principal to contract principal
;; tx-sender context can change 

(define-constant price u1000000) ;; = 1 STX

(define-data-var total-posts uint u0) ;; increment as the function writes the post

(define-map posts principal (string-utf8 500)) ;; key (value) 'ST--------- : "Hello, world"

(define-read-only (get-total-posts)
    (var-get total-posts)
)
;; less computation

(define-read-only (get-post (user principal)) 
    (map-get? posts user)
)

(define-public (write-post (message (string-utf8 500))) ;; receiving data but your're not checking the message, OK for now, user right 
    (begin
        (unwrap! (stx-transfer? price tx-sender contract-owner) (err "TRANSFER_FAILED"))        
        ;; (try! (stx-transfer? price tx-sender contract-owner))
        ;; #[allow(unchecked_data)]
        ;; unwrap gives additional functionality over "try!" by posting a throw message
        (map-set posts tx-sender message)
        (var-set total-posts (+ (var-get total-posts) u1))
        (ok "Success!")
    )
)
;; try and fail, then the function aborts
;; use your variables
;; function: (signature) (body) - > limited to one expression