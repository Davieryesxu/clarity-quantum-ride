;; QuantumRide Payment Contract

(use-trait ft-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-010-trait-ft-standard.sip-010-trait)

(define-constant contract-owner tx-sender)

(define-map payment-escrow
  uint
  {
    amount: uint,
    token-contract: principal,
    released: bool
  }
)

(define-public (deposit-payment 
  (ride-id uint) 
  (token <ft-trait>) 
  (amount uint)
)
  (begin
    (try! (contract-call? token transfer
      amount
      tx-sender
      (as-contract tx-sender)
      none
    ))
    (ok (map-set payment-escrow
      ride-id
      {
        amount: amount,
        token-contract: (contract-of token),
        released: false
      }
    ))
  )
)

(define-public (release-payment (ride-id uint))
  (let
    (
      (escrow (unwrap! (map-get? payment-escrow ride-id) (err u101)))
      (ride (unwrap! (contract-call? .quantum-ride get-ride ride-id) (err u102)))
    )
    (begin
      (asserts! (not (get released escrow)) (err u103))
      (asserts! (is-eq (get status ride) "completed") (err u104))
      (as-contract
        (contract-call? .quantum-ride-token transfer
          (get amount escrow)
          tx-sender
          (unwrap! (get driver ride) (err u105))
          none
        )
      )
    )
  )
)
