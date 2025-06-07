;; eco-footprint.clar
(define-map footprints
  ((user principal))
  ((total uint)
   (entries (list 100 (tuple (activity (string-ascii 32)) (amount uint)))))

(define-public (add-entry (activity (string-ascii 32)) (amount uint))
  (let (
        (caller tx-sender)
        (fp (default-to { total: u0, entries: [] }
                       (map-get? footprints { user: caller })))
        (new-total (+ fp.total amount))
        (new-entries (list-push fp.entries (tuple (activity activity) (amount amount))))
       )
    (map-set footprints
      { user: caller }
      { total: new-total, entries: new-entries })
    (ok new-total)))

(define-read-only (get-total (user principal))
  (match (map-get? footprints { user: user })
    entry (ok entry.total)
    (ok u0)))
