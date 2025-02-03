;; QuantumRide Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-not-found (err u101))
(define-constant err-invalid-state (err u102))

;; Data Variables
(define-map drivers 
  principal
  {
    status: (string-ascii 20),
    rating: uint,
    total-rides: uint,
    verified: bool
  }
)

(define-map rides
  uint
  {
    rider: principal,
    driver: (optional principal),
    pickup: (string-utf8 100),
    dropoff: (string-utf8 100),
    fare: uint,
    status: (string-ascii 20),
    timestamp: uint
  }
)

(define-data-var ride-counter uint u0)

;; Public Functions
(define-public (register-driver)
  (begin
    (asserts! (is-none (get-driver tx-sender)) (err u103))
    (ok (map-set drivers
      tx-sender
      {
        status: "available",
        rating: u0,
        total-rides: u0,
        verified: false
      }
    ))
  )
)

(define-public (request-ride (pickup (string-utf8 100)) (dropoff (string-utf8 100)) (fare uint))
  (let
    (
      (ride-id (+ (var-get ride-counter) u1))
    )
    (begin
      (var-set ride-counter ride-id)
      (ok (map-set rides
        ride-id
        {
          rider: tx-sender,
          driver: none,
          pickup: pickup,
          dropoff: dropoff,
          fare: fare,
          status: "requested",
          timestamp: block-height
        }
      ))
    )
  )
)

(define-public (accept-ride (ride-id uint))
  (let
    (
      (ride (unwrap! (map-get? rides ride-id) (err u101)))
      (driver (unwrap! (get-driver tx-sender) (err u104)))
    )
    (begin
      (asserts! (is-eq (get status driver) "available") (err u105))
      (asserts! (is-eq (get status ride) "requested") (err u106))
      (ok (map-set rides
        ride-id
        (merge ride { 
          driver: (some tx-sender),
          status: "accepted"
        })
      ))
    )
  )
)

;; Read Only Functions
(define-read-only (get-driver (address principal))
  (map-get? drivers address)
)

(define-read-only (get-ride (ride-id uint))
  (map-get? rides ride-id)
)
