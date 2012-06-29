(defun counter (init increment)
  (let cur init)
  (fn ()
    (let prev cur)
    (set! cur (+ cur increment))
    prev
  )
)

(let c10 (counter 10 1))
(let c100 (counter 100 10))

(print (c10))  ; 10
(print (c10))  ; 11
(print (c100)) ; 100
(print (c10))  ; 12
(print (c100)) ; 110
