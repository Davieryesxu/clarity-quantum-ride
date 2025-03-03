;; QuantumRide Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-not-found (err u101))
(define-constant err-invalid-state (err u102))
(define-constant err-invalid-amount (err u107))
(define-constant err-already-registered (err u103))
(define-constant err-driver-not-found (err u104))
(define-constant err-driver-not-available (err u105))
(define-constant err-invalid-ride-state (err u106))

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
    (asserts! (is-none (get-driver tx-sender)) err-already-registered)
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

(define-public (verify-driver (driver principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (asserts! (is-some (get-driver driver)) err-driver-not-found)
    (ok (map-set drivers
      driver
      (merge (unwrap! (get-driver driver) err-driver-not-found)
        { verified: true })
    ))
  )
)

(define-public (request-ride (pickup (string-utf8 100)) (dropoff (string-utf8 100)) (fare uint))
  (begin
    (asserts! (> fare u0) err-invalid-amount)
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
)

(define-public (accept-ride (ride-id uint))
  (let
    (
      (ride (unwrap! (map-get? rides ride-id) err-not-found))
      (driver (unwrap! (get-driver tx-sender) err-driver-not-found))
    )
    (begin
      (asserts! (get verified driver) err-unauthorized)
      (asserts! (is-eq (get status driver) "available") err-driver-not-available)
      (asserts! (is-eq (get status ride) "requested") err-invalid-ride-state)
      (map-set drivers
        tx-sender
        (merge driver { status: "busy" })
      )
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

(define-public (complete-ride (ride-id uint))
  (let
    (
      (ride (unwrap! (map-get? rides ride-id) err-not-found))
    )
    (begin
      (asserts! (is-eq (some tx-sender) (get driver ride)) err-unauthorized)
      (asserts! (is-eq (get status ride) "accepted") err-invalid-state)
      (map-set drivers
        tx-sender
        (merge (unwrap! (get-driver tx-sender) err-driver-not-found)
          { 
            status: "available",
            total-rides: (+ (get total-rides (unwrap! (get-driver tx-sender) err-driver-not-found)) u1)
          }
        )
      )
      (ok (map-set rides
        ride-id
        (merge ride { status: "completed" })
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
