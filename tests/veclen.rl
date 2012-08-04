(defun sqrt (x) [Math sqrt x])

(defun veclen (x y)
  (let x2 (* x x))
  (let y2 (* y y))
  (let z2 (+ x2 y2))
  (sqrt z2)
)
(print (veclen 3 4))
