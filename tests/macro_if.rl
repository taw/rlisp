(defmacro myif (c a b)
 `(if ,c
    ,a
    ,b
  )
)
                  
(myif (> 2 1) (print "Hello") (print "World"))
