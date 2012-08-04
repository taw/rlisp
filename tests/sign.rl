(defun sign (x)
  (cond
    (>  x 0) 1
    (== x 0) 0
    -1
  )
)

(print (sign 42))
(print (sign 0))
(print (sign -8))
