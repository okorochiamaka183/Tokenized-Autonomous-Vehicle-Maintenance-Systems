;; Parts Sourcing Contract
;; Locates genuine replacement components at competitive prices

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-PART-NOT-FOUND (err u401))
(define-constant ERR-INVALID-INPUT (err u402))
(define-constant ERR-ALREADY-EXISTS (err u403))
(define-constant ERR-SUPPLIER-NOT-FOUND (err u404))
(define-constant ERR-ORDER-NOT-FOUND (err u405))

;; Data Variables
(define-data-var next-part-id uint u1)
(define-data-var next-order-id uint u1)
(define-data-var next-quote-id uint u1)

;; Data Maps
(define-map parts-catalog
  { part-id: uint }
  {
    part-number: (string-ascii 50),
    name: (string-ascii 100),
    description: (string-ascii 300),
    category: (string-ascii 50),
    manufacturer: (string-ascii 50),
    compatible-vehicles: (list 20 (string-ascii 30)),
    genuine: bool,
    active: bool,
    created-at: uint
  }
)

(define-map suppliers
  { supplier-id: principal }
  {
    name: (string-ascii 50),
    location: (string-ascii 100),
    contact-info: (string-ascii 200),
    specialties: (list 10 (string-ascii 30)),
    rating: uint,
    verified: bool,
    active: bool,
    registered-at: uint
  }
)

(define-map part-inventory
  { supplier-id: principal, part-id: uint }
  {
    quantity-available: uint,
    unit-price: uint,
    bulk-discount: uint,
    lead-time-days: uint,
    last-updated: uint,
    quality-grade: (string-ascii 20)
  }
)

(define-map parts-orders
  { order-id: uint }
  {
    vehicle-id: uint,
    part-id: uint,
    supplier-id: principal,
    quantity: uint,
    unit-price: uint,
    total-cost: uint,
    order-date: uint,
    expected-delivery: uint,
    status: (string-ascii 20),
    tracking-number: (optional (string-ascii 50)),
    delivered-date: (optional uint)
  }
)

(define-map price-quotes
  { quote-id: uint }
  {
    part-id: uint,
    supplier-id: principal,
    quantity: uint,
    quoted-price: uint,
    valid-until: uint,
    terms: (string-ascii 200),
    created-at: uint,
    accepted: bool
  }
)

(define-map part-reviews
  { part-id: uint, review-id: uint }
  {
    reviewer: principal,
    rating: uint,
    review-text: (string-ascii 500),
    verified-purchase: bool,
    review-date: uint,
    helpful-votes: uint
  }
)

;; Private Functions
(define-private (is-valid-order-status (status (string-ascii 20)))
  (or (is-eq status "pending")
      (or (is-eq status "confirmed")
          (or (is-eq status "shipped")
              (or (is-eq status "delivered")
                  (or (is-eq status "cancelled")
                      (is-eq status "returned"))))))
)

(define-private (calculate-total-cost (quantity uint) (unit-price uint) (bulk-discount uint))
  (let ((subtotal (* quantity unit-price))
        (discount-amount (if (> quantity u10) (/ (* subtotal bulk-discount) u100) u0)))
    (- subtotal discount-amount)
  )
)

;; Public Functions
(define-public (register-supplier (name (string-ascii 50)) (location (string-ascii 100)) (contact-info (string-ascii 200)) (specialties (list 10 (string-ascii 30))))
  (begin
    (asserts! (is-none (map-get? suppliers { supplier-id: tx-sender })) ERR-ALREADY-EXISTS)
    (map-set suppliers
      { supplier-id: tx-sender }
      {
        name: name,
        location: location,
        contact-info: contact-info,
        specialties: specialties,
        rating: u50,
        verified: false,
        active: true,
        registered-at: block-height
      }
    )
    (ok true)
  )
)

(define-public (add-part-to-catalog (part-number (string-ascii 50)) (name (string-ascii 100)) (description (string-ascii 300)) (category (string-ascii 50)) (manufacturer (string-ascii 50)) (compatible-vehicles (list 20 (string-ascii 30))) (genuine bool))
  (let ((part-id (var-get next-part-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set parts-catalog
      { part-id: part-id }
      {
        part-number: part-number,
        name: name,
        description: description,
        category: category,
        manufacturer: manufacturer,
        compatible-vehicles: compatible-vehicles,
        genuine: genuine,
        active: true,
        created-at: block-height
      }
    )
    (var-set next-part-id (+ part-id u1))
    (ok part-id)
  )
)

(define-public (update-inventory (part-id uint) (quantity-available uint) (unit-price uint) (bulk-discount uint) (lead-time-days uint) (quality-grade (string-ascii 20)))
  (begin
    (asserts! (is-some (map-get? suppliers { supplier-id: tx-sender })) ERR-SUPPLIER-NOT-FOUND)
    (asserts! (is-some (map-get? parts-catalog { part-id: part-id })) ERR-PART-NOT-FOUND)
    (asserts! (and (> unit-price u0) (<= bulk-discount u50) (> lead-time-days u0)) ERR-INVALID-INPUT)
    (map-set part-inventory
      { supplier-id: tx-sender, part-id: part-id }
      {
        quantity-available: quantity-available,
        unit-price: unit-price,
        bulk-discount: bulk-discount,
        lead-time-days: lead-time-days,
        last-updated: block-height,
        quality-grade: quality-grade
      }
    )
    (ok true)
  )
)

(define-public (create-price-quote (part-id uint) (quantity uint) (quoted-price uint) (valid-days uint) (terms (string-ascii 200)))
  (let ((quote-id (var-get next-quote-id)))
    (asserts! (is-some (map-get? suppliers { supplier-id: tx-sender })) ERR-SUPPLIER-NOT-FOUND)
    (asserts! (is-some (map-get? parts-catalog { part-id: part-id })) ERR-PART-NOT-FOUND)
    (asserts! (and (> quantity u0) (> quoted-price u0) (> valid-days u0)) ERR-INVALID-INPUT)
    (map-set price-quotes
      { quote-id: quote-id }
      {
        part-id: part-id,
        supplier-id: tx-sender,
        quantity: quantity,
        quoted-price: quoted-price,
        valid-until: (+ block-height valid-days),
        terms: terms,
        created-at: block-height,
        accepted: false
      }
    )
    (var-set next-quote-id (+ quote-id u1))
    (ok quote-id)
  )
)

(define-public (place-order (vehicle-id uint) (part-id uint) (supplier-id principal) (quantity uint))
  (let ((order-id (var-get next-order-id))
        (inventory-data (unwrap! (map-get? part-inventory { supplier-id: supplier-id, part-id: part-id }) ERR-PART-NOT-FOUND)))
    (asserts! (>= (get quantity-available inventory-data) quantity) ERR-INVALID-INPUT)
    (asserts! (> quantity u0) ERR-INVALID-INPUT)
    (let ((unit-price (get unit-price inventory-data))
          (bulk-discount (get bulk-discount inventory-data))
          (total-cost (calculate-total-cost quantity unit-price bulk-discount))
          (lead-time (get lead-time-days inventory-data)))
      (map-set parts-orders
        { order-id: order-id }
        {
          vehicle-id: vehicle-id,
          part-id: part-id,
          supplier-id: supplier-id,
          quantity: quantity,
          unit-price: unit-price,
          total-cost: total-cost,
          order-date: block-height,
          expected-delivery: (+ block-height lead-time),
          status: "pending",
          tracking-number: none,
          delivered-date: none
        }
      )
      (map-set part-inventory
        { supplier-id: supplier-id, part-id: part-id }
        (merge inventory-data { quantity-available: (- (get quantity-available inventory-data) quantity) })
      )
      (var-set next-order-id (+ order-id u1))
      (ok order-id)
    )
  )
)

(define-public (update-order-status (order-id uint) (new-status (string-ascii 20)) (tracking-number (optional (string-ascii 50))))
  (let ((order-data (unwrap! (map-get? parts-orders { order-id: order-id }) ERR-ORDER-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get supplier-id order-data)) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-order-status new-status) ERR-INVALID-INPUT)
    (map-set parts-orders
      { order-id: order-id }
      (merge order-data
             { status: new-status,
               tracking-number: tracking-number,
               delivered-date: (if (is-eq new-status "delivered") (some block-height) (get delivered-date order-data)) })
    )
    (ok true)
  )
)

(define-public (submit-part-review (part-id uint) (review-id uint) (rating uint) (review-text (string-ascii 500)) (verified-purchase bool))
  (begin
    (asserts! (is-some (map-get? parts-catalog { part-id: part-id })) ERR-PART-NOT-FOUND)
    (asserts! (and (<= rating u5) (> rating u0)) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? part-reviews { part-id: part-id, review-id: review-id })) ERR-ALREADY-EXISTS)
    (map-set part-reviews
      { part-id: part-id, review-id: review-id }
      {
        reviewer: tx-sender,
        rating: rating,
        review-text: review-text,
        verified-purchase: verified-purchase,
        review-date: block-height,
        helpful-votes: u0
      }
    )
    (ok true)
  )
)

(define-public (verify-supplier (supplier-id principal))
  (let ((supplier-data (unwrap! (map-get? suppliers { supplier-id: supplier-id }) ERR-SUPPLIER-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set suppliers
      { supplier-id: supplier-id }
      (merge supplier-data { verified: true })
    )
    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-part-info (part-id uint))
  (map-get? parts-catalog { part-id: part-id })
)

(define-read-only (get-supplier-info (supplier-id principal))
  (map-get? suppliers { supplier-id: supplier-id })
)

(define-read-only (get-inventory (supplier-id principal) (part-id uint))
  (map-get? part-inventory { supplier-id: supplier-id, part-id: part-id })
)

(define-read-only (get-order (order-id uint))
  (map-get? parts-orders { order-id: order-id })
)

(define-read-only (get-quote (quote-id uint))
  (map-get? price-quotes { quote-id: quote-id })
)

(define-read-only (get-part-review (part-id uint) (review-id uint))
  (map-get? part-reviews { part-id: part-id, review-id: review-id })
)

(define-read-only (get-next-part-id)
  (var-get next-part-id)
)

(define-read-only (get-next-order-id)
  (var-get next-order-id)
)

(define-read-only (get-next-quote-id)
  (var-get next-quote-id)
)
