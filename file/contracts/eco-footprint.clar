;; Enhanced Eco-Footprint Calculator Contract
;; Fixes: list syntax, adds bounds checking, improves security

;; Error constants
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-ACTIVITY-TOO-LONG (err u102))
(define-constant ERR-MAX-ENTRIES-REACHED (err u103))
(define-constant ERR-USER-NOT-FOUND (err u104))

;; Constants
(define-constant MAX-ENTRIES u100)
(define-constant MAX-ACTIVITY-LENGTH u32)
(define-constant MIN-AMOUNT u1)
(define-constant MAX-AMOUNT u1000000) ;; Reasonable upper bound

;; Data structures
(define-map footprints
  { user: principal }
  { total: uint,
    entries: (list 100 { activity: (string-ascii 32), amount: uint, timestamp: uint }) })

;; Track total users for statistics
(define-data-var total-users uint u0)

;; Add footprint entry with enhanced validation
(define-public (add-entry (activity (string-ascii 32)) (amount uint))
  (let (
        (caller tx-sender)
        (current-block-height block-height)
        (fp (default-to { total: u0, entries: (list) }
                       (map-get? footprints { user: caller })))
        (current-entries-count (len (get entries fp)))
       )
    ;; Validation checks
    (asserts! (and (>= amount MIN-AMOUNT) (<= amount MAX-AMOUNT)) ERR-INVALID-AMOUNT)
    (asserts! (<= (len activity) MAX-ACTIVITY-LENGTH) ERR-ACTIVITY-TOO-LONG)
    (asserts! (< current-entries-count MAX-ENTRIES) ERR-MAX-ENTRIES-REACHED)
    
    (let (
          (new-total (+ (get total fp) amount))
          (new-entry { activity: activity, amount: amount, timestamp: current-block-height })
          (updated-entries (unwrap! (as-max-len? (append (get entries fp) new-entry) u100) ERR-MAX-ENTRIES-REACHED))
         )
      ;; If this is the user's first entry, increment user count
      (if (is-eq (get total fp) u0)
          (var-set total-users (+ (var-get total-users) u1))
          true)
      
      (map-set footprints
        { user: caller }
        { total: new-total, entries: updated-entries })
      (ok new-total))))

;; Get user's total footprint
(define-read-only (get-total (user principal))
  (match (map-get? footprints { user: user })
    entry (ok (get total entry))
    (ok u0)))

;; Get user's detailed footprint data
(define-read-only (get-user-footprint (user principal))
  (match (map-get? footprints { user: user })
    entry (ok entry)
    ERR-USER-NOT-FOUND))

;; Get number of entries for a user
(define-read-only (get-entry-count (user principal))
  (match (map-get? footprints { user: user })
    entry (ok (len (get entries entry)))
    (ok u0)))

;; Get total number of users
(define-read-only (get-total-users)
  (ok (var-get total-users)))

;; Calculate average footprint per user (returns 0 if no users)
(define-read-only (get-average-footprint)
  (let ((users (var-get total-users)))
    (if (> users u0)
        (ok (/ (get-global-total) users))
        (ok u0))))

;; Helper function to calculate global total (private)
(define-private (get-global-total)
  ;; This is a simplified version - in a real implementation,
  ;; you might want to maintain a global counter for efficiency
  u0) ;; Placeholder - would need iteration over all users

;; Get a specific entry by index
(define-read-only (get-entry (user principal) (entry-index uint))
  (match (map-get? footprints { user: user })
    fp (match (element-at (get entries fp) entry-index)
         entry (ok entry)
         ERR-INVALID-AMOUNT)
    ERR-USER-NOT-FOUND))

;; Reset user's footprint (delete all entries)
(define-public (reset-footprint)
  (let ((caller tx-sender)
        (had-entries (is-some (map-get? footprints { user: caller }))))
    (map-delete footprints { user: caller })
    ;; Decrement user count if they had entries
    (if had-entries
        (var-set total-users (- (var-get total-users) u1))
        true)
    (ok true)))
