(require "rlunit.rl")

(defun start-readable-gensym ()
  (let sid 0)
  (set! gensym
    (fn ()
       (let sym [(+ "tmp-" [sid to_s]) to_sym])
       (set! sid (+ 1 sid))
       sym
    )
  )
)

(test-suite Hash_Syntax
  (test hash-add-elements ; Helper macro
    (assert        (hash-add-elements foo (a: 100))
     macroexpands: (send foo 'set 'a 100)
    )
    (assert        (hash-add-elements foo (a: 100 b: 200))
     macroexpands: (do
                     (send foo 'set 'a 100)
                     (send foo 'set 'b 200)
                    )
    ))
  (test hash; Real macro
    (start-readable-gensym)
    (assert        (hash)
     macroexpands: (do
                   (let tmp-0 (send Hash 'new)) (do) tmp-0)
    )))
