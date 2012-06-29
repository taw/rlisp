(defun fib (n)
  (if (<= n 1)
    1
    (+ (fib (- n 1)) (fib (- n 2)))
  )
)
(print (map fib '(1 2 3 4 5)))
