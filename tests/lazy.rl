(defmacro delay code
 `(local
    ; Variable capture possible
    (let lazy-computation-result nil)
    (let lazy-computation-completed false)
    (fn ()
      (if lazy-computation-completed
        lazy-computation-result
        (do
          (set! lazy-computation-result (do ,@code))
          (set! lazy-computation-completed true)
          lazy-computation-result
        )
      )
    )
  )
)

(defun force (code) (code))

(print (force (delay "Hello")))
(print (force (delay (+ 2 2))))

(let a (delay (print "Never executed...") "no way"))
(let b (delay (print "Computing...") "result"))

(print (force b))
(print (force b))
