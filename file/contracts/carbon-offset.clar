;; Carbon Offset Tracking Contract
;; Allows users to track carbon offsets and calculate net footprint

;; Error constants
(define-constant ERR-UNAUTHORIZED (err u200))
(define-constant ERR-INVALID-AMOUNT (err u201))
(define-constant ERR-INVALID-OFFSET-TYPE (err u202))
(define-constant ERR-INSUFFICIENT-BALANCE (err u203))
(define-constant ERR-OFFSET-NOT-FOUND (err u204))
(define-constant ERR-INVALID-PRICE (err u205))
(define-constant ERR-INVALID-PRINCIPAL (err u206))

;; Constants
(define-constant MAX-OFFSET-ENTRIES u50)
(define-constant MIN-OFFSET-AMOUNT u1)
(define-constant MAX-OFFSET-AMOUNT u100000)
(define-constant MAX-PRICE-PER-UNIT u1000)
(define-constant MIN-PRICE-PER-UNIT u1)

;; Valid offset types
(define-constant OFFSET-TREE-PLANTING "tree-planting")
(define-constant OFFSET-RENEWABLE-ENERGY "renewable-energy")
(define-constant OFFSET-CARBON-CAPTURE "carbon-capture")
(define-constant OFFSET-FOREST-CONSERVATION "forest-conservation")

;; Data structures
(define-map carbon-offsets
  { user: principal }
  { total-offset: uint,
    offsets: (list 50 { 
      offset-type: (string-ascii 32), 
      amount: uint, 
      timestamp: uint, 
      verified: bool,
      cost: uint }) })

;; Verification authority (could be expanded to multiple authorities)
(define-data-var offset-verifier principal tx-sender)

;; Offset pricing (amount per unit of carbon offset)
(define-map offset-prices
  { offset-type: (string-ascii 32) }
  { price-per-unit: uint })

;; Initialize offset prices
(map-set offset-prices { offset-type: OFFSET-TREE-PLANTING } { price-per-unit: u10 })
(map-set offset-prices { offset-type: OFFSET-RENEWABLE-ENERGY } { price-per-unit: u15 })
(map-set offset-prices { offset-type: OFFSET-CARBON-CAPTURE } { price-per-unit: u25 })
(map-set offset-prices { offset-type: OFFSET-FOREST-CONSERVATION } { price-per-unit: u20 })

;; Helper function to validate offset type
(define-private (is-valid-offset-type (offset-type (string-ascii 32)))
  (or (is-eq offset-type OFFSET-TREE-PLANTING)
      (or (is-eq offset-type OFFSET-RENEWABLE-ENERGY)
          (or (is-eq offset-type OFFSET-CARBON-CAPTURE)
              (is-eq offset-type OFFSET-FOREST-CONSERVATION)))))

;; Helper function to validate price range
(define-private (is-valid-price (price uint))
  (and (>= price MIN-PRICE-PER-UNIT) (<= price MAX-PRICE-PER-UNIT)))

;; Helper function to validate if a principal is not null/zero
(define-private (is-valid-principal (user principal))
  ;; In Clarity, we can't directly check for null principals, but we can ensure
  ;; the principal is not the same as a known invalid state
  ;; This is a basic validation - in practice, you might have more specific checks
  (not (is-eq user 'SP000000000000000000002Q6VF78)))

;; Purchase carbon offset
(define-public (purchase-offset (offset-type (string-ascii 32)) (amount uint))
  (let (
        (caller tx-sender)
        (current-block-height block-height)
        (offset-data (default-to { total-offset: u0, offsets: (list) }
                                 (map-get? carbon-offsets { user: caller })))
        (price-info (unwrap! (map-get? offset-prices { offset-type: offset-type }) ERR-INVALID-OFFSET-TYPE))
        (total-cost (* amount (get price-per-unit price-info)))
       )
    ;; Validation
    (asserts! (is-valid-offset-type offset-type) ERR-INVALID-OFFSET-TYPE)
    (asserts! (and (>= amount MIN-OFFSET-AMOUNT) (<= amount MAX-OFFSET-AMOUNT)) ERR-INVALID-AMOUNT)
    (asserts! (< (len (get offsets offset-data)) MAX-OFFSET-ENTRIES) ERR-INVALID-AMOUNT)
    
    (let (
          (new-total-offset (+ (get total-offset offset-data) amount))
          (new-offset-entry { 
            offset-type: offset-type, 
            amount: amount, 
            timestamp: current-block-height, 
            verified: false,
            cost: total-cost })
          (updated-offsets (unwrap! (as-max-len? (append (get offsets offset-data) new-offset-entry) u50) ERR-INVALID-AMOUNT))
         )
      (map-set carbon-offsets
        { user: caller }
        { total-offset: new-total-offset, offsets: updated-offsets })
      (ok { total-offset: new-total-offset, cost: total-cost }))))

;; Verify offset (only by authorized verifier) - simplified approach
(define-public (verify-all-offsets (user principal))
  (let (
        (caller tx-sender)
       )
    ;; Validate inputs
    (asserts! (is-eq caller (var-get offset-verifier)) ERR-UNAUTHORIZED)
    (asserts! (is-valid-principal user) ERR-INVALID-PRINCIPAL)
    
    ;; Check if user has offsets to verify
    (match (map-get? carbon-offsets { user: user })
      offset-data (begin
        ;; For simplicity, this verifies all unverified offsets for a user
        ;; In a real implementation, you might want more granular control
        (map-set carbon-offsets
          { user: user }
          { total-offset: (get total-offset offset-data), 
            offsets: (map verify-single-offset (get offsets offset-data)) })
        (ok true))
      ERR-OFFSET-NOT-FOUND)))

;; Helper function to verify a single offset
(define-private (verify-single-offset 
  (offset { offset-type: (string-ascii 32), amount: uint, timestamp: uint, verified: bool, cost: uint }))
  (merge offset { verified: true }))

;; Get a specific offset entry by index
(define-read-only (get-offset-entry (user principal) (offset-index uint))
  (match (map-get? carbon-offsets { user: user })
    offset-data (match (element-at (get offsets offset-data) offset-index)
                  entry (ok entry)
                  ERR-INVALID-AMOUNT)
    ERR-OFFSET-NOT-FOUND))

;; Get user's total verified offsets
(define-read-only (get-verified-offsets (user principal))
  (match (map-get? carbon-offsets { user: user })
    offset-data (ok (fold calculate-verified-total (get offsets offset-data) u0))
    (ok u0)))

;; Helper function for calculating verified offsets
(define-private (calculate-verified-total 
  (offset { offset-type: (string-ascii 32), amount: uint, timestamp: uint, verified: bool, cost: uint }) 
  (acc uint))
  (if (get verified offset)
      (+ acc (get amount offset))
      acc))

;; Get user's offset details
(define-read-only (get-user-offsets (user principal))
  (match (map-get? carbon-offsets { user: user })
    offset-data (ok offset-data)
    ERR-OFFSET-NOT-FOUND))

;; Get offset price for a specific type
(define-read-only (get-offset-price (offset-type (string-ascii 32)))
  (match (map-get? offset-prices { offset-type: offset-type })
    price-info (ok (get price-per-unit price-info))
    ERR-INVALID-OFFSET-TYPE))

;; Update offset price (only by verifier)
(define-public (update-offset-price (offset-type (string-ascii 32)) (new-price uint))
  (begin
    ;; Validate authorization
    (asserts! (is-eq tx-sender (var-get offset-verifier)) ERR-UNAUTHORIZED)
    ;; Validate offset type
    (asserts! (is-valid-offset-type offset-type) ERR-INVALID-OFFSET-TYPE)
    ;; Validate price range
    (asserts! (is-valid-price new-price) ERR-INVALID-PRICE)
    
    ;; Update the price
    (map-set offset-prices { offset-type: offset-type } { price-per-unit: new-price })
    (ok true)))

;; Change verifier (only current verifier can do this)
(define-public (change-verifier (new-verifier principal))
  (begin
    ;; Validate authorization
    (asserts! (is-eq tx-sender (var-get offset-verifier)) ERR-UNAUTHORIZED)
    ;; Validate the new verifier principal
    (asserts! (is-valid-principal new-verifier) ERR-INVALID-PRINCIPAL)
    ;; Ensure new verifier is different from current verifier
    (asserts! (not (is-eq new-verifier (var-get offset-verifier))) ERR-INVALID-PRINCIPAL)
    
    ;; Update the verifier
    (var-set offset-verifier new-verifier)
    (ok true)))

;; Get current verifier
(define-read-only (get-verifier)
  (ok (var-get offset-verifier)))
