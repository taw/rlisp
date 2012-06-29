; Arc-like let
(defmacro local-let args
 `(local
    (let ,[args get 0] ,[args get 1])
  ,@(tl (tl args))
  )
)
(let x 2)
(local-let x 3 (print x))
(print x)
