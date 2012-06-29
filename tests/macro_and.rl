(defmacro my-and (arg . args)
  (if (empty? args)
    arg
    (do
      (let tmp (gensym))
     `(do
        (let ,tmp ,arg)
        (if ,tmp
          (my-and ,@args)
          ,tmp
        )
      )
    )
  )
)

(print (my-and false (+ 3 4) (+ 5 6)))
(print (my-and (+ 3 4) false (+ 5 6)))
(print (my-and (+ 3 4) (+ 5 6) (+ 7 8)))
