;; Service Scheduling Contract
;; Coordinates oil changes, tire rotations, and routine maintenance

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-SERVICE-NOT-FOUND (err u201))
(define-constant ERR-INVALID-INPUT (err u202))
(define-constant ERR-ALREADY-EXISTS (err u203))
(define-constant ERR-INVALID-STATUS (err u204))

;; Data Variables
(define-data-var next-service-id uint u1)
(define-data-var next-appointment-id uint u1)

;; Data Maps
(define-map service-providers
  { provider-id: principal }
  {
    name: (string-ascii 50),
    location: (string-ascii 100),
    specialties: (list 10 (string-ascii 30)),
    rating: uint,
    active: bool,
    registered-at: uint
  }
)

(define-map service-types
  { service-type-id: uint }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    estimated-duration: uint,
    base-cost: uint,
    frequency-miles: uint,
    active: bool
  }
)

(define-map service-appointments
  { appointment-id: uint }
  {
    vehicle-id: uint,
    service-type-id: uint,
    provider-id: principal,
    scheduled-date: uint,
    estimated-cost: uint,
    status: (string-ascii 20),
    notes: (string-ascii 300),
    created-at: uint,
    completed-at: (optional uint)
  }
)

(define-map service-history
  { vehicle-id: uint, service-id: uint }
  {
    service-type-id: uint,
    provider-id: principal,
    service-date: uint,
    mileage-at-service: uint,
    cost: uint,
    quality-rating: uint,
    notes: (string-ascii 300),
    next-service-due: uint
  }
)

(define-map vehicle-service-schedule
  { vehicle-id: uint }
  {
    last-oil-change: uint,
    last-tire-rotation: uint,
    last-brake-service: uint,
    last-inspection: uint,
    next-oil-change-due: uint,
    next-tire-rotation-due: uint,
    next-brake-service-due: uint,
    next-inspection-due: uint
  }
)

;; Private Functions
(define-private (is-valid-status (status (string-ascii 20)))
  (or (is-eq status "scheduled")
      (or (is-eq status "confirmed")
          (or (is-eq status "in-progress")
              (or (is-eq status "completed")
                  (is-eq status "cancelled")))))
)

;; Public Functions
(define-public (register-service-provider (name (string-ascii 50)) (location (string-ascii 100)) (specialties (list 10 (string-ascii 30))))
  (begin
    (asserts! (is-none (map-get? service-providers { provider-id: tx-sender })) ERR-ALREADY-EXISTS)
    (map-set service-providers
      { provider-id: tx-sender }
      {
        name: name,
        location: location,
        specialties: specialties,
        rating: u50,
        active: true,
        registered-at: block-height
      }
    )
    (ok true)
  )
)

(define-public (create-service-type (service-type-id uint) (name (string-ascii 50)) (description (string-ascii 200)) (estimated-duration uint) (base-cost uint) (frequency-miles uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? service-types { service-type-id: service-type-id })) ERR-ALREADY-EXISTS)
    (asserts! (and (> estimated-duration u0) (> base-cost u0) (> frequency-miles u0)) ERR-INVALID-INPUT)
    (map-set service-types
      { service-type-id: service-type-id }
      {
        name: name,
        description: description,
        estimated-duration: estimated-duration,
        base-cost: base-cost,
        frequency-miles: frequency-miles,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (schedule-appointment (vehicle-id uint) (service-type-id uint) (provider-id principal) (scheduled-date uint) (estimated-cost uint) (notes (string-ascii 300)))
  (let ((appointment-id (var-get next-appointment-id)))
    (asserts! (is-some (map-get? service-types { service-type-id: service-type-id })) ERR-SERVICE-NOT-FOUND)
    (asserts! (is-some (map-get? service-providers { provider-id: provider-id })) ERR-SERVICE-NOT-FOUND)
    (asserts! (> scheduled-date block-height) ERR-INVALID-INPUT)
    (asserts! (> estimated-cost u0) ERR-INVALID-INPUT)
    (map-set service-appointments
      { appointment-id: appointment-id }
      {
        vehicle-id: vehicle-id,
        service-type-id: service-type-id,
        provider-id: provider-id,
        scheduled-date: scheduled-date,
        estimated-cost: estimated-cost,
        status: "scheduled",
        notes: notes,
        created-at: block-height,
        completed-at: none
      }
    )
    (var-set next-appointment-id (+ appointment-id u1))
    (ok appointment-id)
  )
)

(define-public (update-appointment-status (appointment-id uint) (new-status (string-ascii 20)))
  (let ((appointment-data (unwrap! (map-get? service-appointments { appointment-id: appointment-id }) ERR-SERVICE-NOT-FOUND)))
    (asserts! (is-valid-status new-status) ERR-INVALID-STATUS)
    (asserts! (or (is-eq tx-sender (get provider-id appointment-data)) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (map-set service-appointments
      { appointment-id: appointment-id }
      (merge appointment-data
             { status: new-status,
               completed-at: (if (is-eq new-status "completed") (some block-height) none) })
    )
    (ok true)
  )
)

(define-public (record-service-completion (vehicle-id uint) (service-type-id uint) (provider-id principal) (mileage-at-service uint) (actual-cost uint) (quality-rating uint) (notes (string-ascii 300)))
  (let ((service-id (var-get next-service-id))
        (service-type-data (unwrap! (map-get? service-types { service-type-id: service-type-id }) ERR-SERVICE-NOT-FOUND)))
    (asserts! (is-eq tx-sender provider-id) ERR-NOT-AUTHORIZED)
    (asserts! (and (<= quality-rating u5) (> quality-rating u0)) ERR-INVALID-INPUT)
    (asserts! (> actual-cost u0) ERR-INVALID-INPUT)
    (let ((next-service-due (+ mileage-at-service (get frequency-miles service-type-data))))
      (map-set service-history
        { vehicle-id: vehicle-id, service-id: service-id }
        {
          service-type-id: service-type-id,
          provider-id: provider-id,
          service-date: block-height,
          mileage-at-service: mileage-at-service,
          cost: actual-cost,
          quality-rating: quality-rating,
          notes: notes,
          next-service-due: next-service-due
        }
      )
      (var-set next-service-id (+ service-id u1))
      (ok service-id)
    )
  )
)

(define-public (update-service-schedule (vehicle-id uint) (service-type (string-ascii 20)) (last-service-mileage uint))
  (let ((current-schedule (default-to
    { last-oil-change: u0, last-tire-rotation: u0, last-brake-service: u0, last-inspection: u0,
      next-oil-change-due: u0, next-tire-rotation-due: u0, next-brake-service-due: u0, next-inspection-due: u0 }
    (map-get? vehicle-service-schedule { vehicle-id: vehicle-id }))))
    (if (is-eq service-type "oil-change")
      (map-set vehicle-service-schedule
        { vehicle-id: vehicle-id }
        (merge current-schedule
               { last-oil-change: last-service-mileage,
                 next-oil-change-due: (+ last-service-mileage u5000) }))
      (if (is-eq service-type "tire-rotation")
        (map-set vehicle-service-schedule
          { vehicle-id: vehicle-id }
          (merge current-schedule
                 { last-tire-rotation: last-service-mileage,
                   next-tire-rotation-due: (+ last-service-mileage u7500) }))
        (if (is-eq service-type "brake-service")
          (map-set vehicle-service-schedule
            { vehicle-id: vehicle-id }
            (merge current-schedule
                   { last-brake-service: last-service-mileage,
                     next-brake-service-due: (+ last-service-mileage u25000) }))
          (map-set vehicle-service-schedule
            { vehicle-id: vehicle-id }
            (merge current-schedule
                   { last-inspection: last-service-mileage,
                     next-inspection-due: (+ last-service-mileage u12000) })))))
    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-service-provider (provider-id principal))
  (map-get? service-providers { provider-id: provider-id })
)

(define-read-only (get-service-type (service-type-id uint))
  (map-get? service-types { service-type-id: service-type-id })
)

(define-read-only (get-appointment (appointment-id uint))
  (map-get? service-appointments { appointment-id: appointment-id })
)

(define-read-only (get-service-history (vehicle-id uint) (service-id uint))
  (map-get? service-history { vehicle-id: vehicle-id, service-id: service-id })
)

(define-read-only (get-vehicle-schedule (vehicle-id uint))
  (map-get? vehicle-service-schedule { vehicle-id: vehicle-id })
)

(define-read-only (get-next-service-id)
  (var-get next-service-id)
)

(define-read-only (get-next-appointment-id)
  (var-get next-appointment-id)
)
