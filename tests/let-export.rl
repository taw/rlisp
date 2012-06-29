; Test let-exporting
(defmacro let-double (x v)
 `(let x (* 2 ,v))
)
(let-double x 2)
(print x) ; -> 4
