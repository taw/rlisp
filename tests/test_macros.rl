#!/home/taw/everything/rlisp/trunk/rlisp

(require "rlunit.rl")

; It's much easier to temporarily replace (gensym)
; with a mock one than to design an assertion system
; which can handle the real one.
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
(defun restore-correct-gensym ()
  (set! gensym (fn () (ruby-eval "$gensym||=0; $gensym+=1; ('#:G' + $gensym.to_s).to_sym")))
)

(test-suite Readable_Gensym
  (test gensym
    (start-readable-gensym)
    (assert 'tmp-0 == (gensym))
    (assert 'tmp-1 == (gensym))
    (assert 'tmp-2 == (gensym))
    (restore-correct-gensym)
    (assert [(gensym) to_s] =~ /\A#:G\d+\Z/)
    (start-readable-gensym)
    (assert 'tmp-0 == (gensym))
    (assert 'tmp-1 == (gensym))
    (start-readable-gensym)
    (assert 'tmp-0 == (gensym))
    (restore-correct-gensym)
    (assert [(gensym) to_s] =~ /\A#:G\d+\Z/)
    (assert (gensym) != (gensym))
  )
  (method teardown () (restore-correct-gensym))
)

(test-suite Basic_Macros
  ; (defun ...) expands to (let ...) and (fn ...)
  (test defun
    (assert        (defun foo () bar)
     macroexpands: (let foo (fn () bar))
    )
    (assert (defun foo (arg . args) bar1 bar2 bar3)
     macroexpands: (let foo (fn (arg . args) bar1 bar2 bar3))
    )
  )
  ; (lambda ...) is simply an alias for (fn ...)
  (test lambda
    (assert        (lambda (arg1 arg2) code code morecode)
     macroexpands: (fn (arg1 arg2) code code morecode)
    )
  )
  ; local creates a nested lexical scope if it's ever needed
  ; It literally creates a closure and executes it
  (test local
    (assert        (local code code2)
     macroexpands: ((fn () code code2))
    )
  )
)

(test-suite OO_Macros
  (test class
    (assert        (class Foo code code2 code3)
     macroexpands: (send Foo 'instance_eval & (fn ()
                     code code2 code3
                   ))
    )
    (assert        (class Foo)
     macroexpands: (send Foo 'instance_eval & (fn ()))
    )
  )
  (test method
    (assert        (method foo (args) body)
     macroexpands: (send self 'define_method 'foo & (fn (args) body))
    )
  )
  ; Should they autoquote ?
  (test attributes
    (assert        (attr-reader 'foo)
     macroexpands: (send self 'attr_reader 'foo)
    )
    (assert        (attr-writer 'foo)
     macroexpands: (send self 'attr_writer 'foo)
    )
    (assert        (attr-accessor 'foo)
     macroexpands: (send self 'attr_accessor 'foo)
    )
  )
)

; value of 'nil is nil, but it's just a identifier. This makes testing
; somewhat difficult.
(test-suite Syntax_Macros
  (test cond
    ;(assert        (cond c1 b1)
    ; macroexpands: (if c1 b1)
    ;)
    (assert        (cond c1 b1 e)
     macroexpands: (if c1 b1 e)
    )
    ;(assert        (cond c1 b1 c2 b2)
    ; macroexpands: (if c1 b1 (if c2 b2 nil))
    ;)
    (assert        (cond c1 b1 c2 b2 e)
     macroexpands: (if c1 b1 (if c2 b2 e))
    )
  )
  (test case
    (start-readable-gensym)
    (assert        (case foo p1 b1 e)
     macroexpands: (do
                     (let tmp-0 foo)
                     (if (send p1 '=== tmp-0) b1 e)
                   )
    )
    (start-readable-gensym)
    (assert        (case foo p1 b1 p2 b2 e)
     macroexpands: (do
                     (let tmp-0 foo)
                     (if (send p1 '=== tmp-0)
                       b1
                       (if (send p2 '=== tmp-0) b2 e)
                     )
                   )
    )
    (restore-correct-gensym)
  )
  (test bool-and
    (assert        (bool-and)
     macroexpands: true
    )
    (assert        (bool-and x)
     macroexpands: x
    )
    (assert        (bool-and x y)
     macroexpands: (if x y false)
    )
    (assert        (bool-and x y z)
     macroexpands: (if x (if y z false) false)
    )
  )
  ; Non-boolean (and ...) is rarely useful.
  ; It's included mostly to preserve symmetry with highly useful
  ; non-boolean (or ...)
  (test and
    (start-readable-gensym)
    (assert       (and)
     macroexpands: true
    )
    (assert (and a b c)
     macroexpands: (do
                     (let tmp-0 a)
                     (if tmp-0
                       (do
                         (let tmp-1 b)
                         (if tmp-1
                            (do
                              (let tmp-2 c)
                              (if tmp-2 true tmp-2)
                            )
                            tmp-1
                         )
                       )
                       tmp-0
                     )
                   )
   )
   (restore-correct-gensym)
  )
  (test or
    (start-readable-gensym)
    (assert        (or)
     macroexpands: false
    )
    (assert        (or a b c)
     macroexpands: (do
                     (let tmp-0 a)
                     (if tmp-0
                       tmp-0
                       (do
                         (let tmp-1 b)
                         (if tmp-1
                           tmp-1
                           (do
                             (let tmp-2 c)
                             (if tmp-2 tmp-2 false)
                           )
                         )
                       )
                     )
                   )
    )
   (restore-correct-gensym)
  )
  (test match_scalar
    (start-readable-gensym)
    (assert        (match foo
                     'x b
                   )
     macroexpands: (do
                     (let tmp-0 foo)
                     (if (send tmp-0 '== 'x)
                       b
                       nil
                     )
                   )
    )
    (start-readable-gensym)
    (assert        (match foo
                     'x  b
                     e
                   )
     macroexpands: (do
                     (let tmp-0 foo)
                     (if (send tmp-0 '== 'x)
                       b
                       e
                     )
                   )
    )
    (start-readable-gensym)
    (assert        (match foo
                     1      b1
                     2.0    b2
                     "foo"  b3
                            e
                   )
     macroexpands: (do
                     (let tmp-0 foo)
                     (if (send tmp-0 '== 1)
                       b1
                       (if (send tmp-0 '== 2.0)
                         b2
                         (if (send tmp-0 '== "foo")
                           b3
                           e
                        )
                      )
                    )
                  )
    )
    (start-readable-gensym)
    (assert        (match foo
                     ()  b1
                     z   b2
                   )
     macroexpands: (do
                     (let tmp-0 foo)
                     (if (send tmp-0 '== ())
                       b1
                       (if (do (let z tmp-0) true)
                         b2
                         nil                   
                       )
                     )
                   )
    )
    ;(start-readable-gensym)
    ; true/false/nil are not keywords, so no luck
    ;(assert
    ;    (match foo
    ;        true   b1
    ;        false  b2
    ;        nil    b3
    ;    )
    ; macroexpands: (do
    ;        (let tmp-0 foo)
    ;        (if (send tmp-0 '== true)
    ;            b1
    ;            (if (send tmp-0 '== false)
    ;                b2
    ;                (if (send tmp-0 '== nil)
    ;                    b3
    ;                    nil
    ;                )
    ;            )
    ;        )
    ;    )
    ;)
    (restore-correct-gensym)
  )
  (test match_list
    (start-readable-gensym)
    (assert        (match foo
                     ()  x e
                   )
     macroexpands: (do
                     (let tmp-0 foo)
                     (if (send tmp-0 '== ())
                       x
                       e
                     )
                   )
   )
   (start-readable-gensym)
   (assert       (match foo
                  ('a)  x e
                 )
   macroexpands: (do
                   (let tmp-0 foo)
                   (if
                     (if
                       (send tmp-0 'is_a? Array)
                       (if (send (send tmp-0 'size) '== 1)
                         (do (let tmp-1 (send tmp-0 'get 0))
                           (send tmp-1 '== 'a)
                         )
                         false
                       )
                       false
                     )
                     x
                     e
                   )
                 )
    )
    (start-readable-gensym)
    (assert        (match foo
                     (v)  x e
                   )
     macroexpands: (do
                     (let tmp-0 foo)
                     (if 
                       (if
                         (send tmp-0 'is_a? Array)
                         (if (send (send tmp-0 'size) '== 1)
                           (do (let tmp-1 (send tmp-0 'get 0))
                             (do (let v tmp-1) true)
                           )
                           false
                         )
                         false
                       )
                       x
                       e
                     )
                   )
    )
    (start-readable-gensym)
    (assert       (match foo
                    (a b)  x e
                  )
    macroexpands: (do
                    (let tmp-0 foo)
                    (if
                      (if
                        (send tmp-0 'is_a? Array)
                        (if (send (send tmp-0 'size) '== 2)
                          (if
                            (do (let tmp-1 (send tmp-0 'get 0))
                              (do (let a tmp-1) true)
                            )
                            (do (let tmp-2 (send tmp-0 'get 1))
                              (do (let b tmp-2) true)
                            )
                            false
                          )
                          false
                        )
                        false
                      )
                      x
                      e
                    )
                  )
    )
    (start-readable-gensym)
    (assert        (match foo
                     (a . b)  x e
                   )
     macroexpands: (do
                     (let tmp-0 foo)
                     (if
                       (if
                         (send tmp-0 'is_a? Array)
                         (if (send (send tmp-0 'size) '>= 1)
                           (if
                             (do (let tmp-1 (send tmp-0 'get 0))
                               (do (let a tmp-1) true)
                             )
                             (do (let tmp-2 (ntl tmp-0 1))
                                (do (let b tmp-2) true)
                             )
                             false
                           )
                           false
                         )
                         false
                       )
                       x
                       e
                     )
                   )
    )
    (restore-correct-gensym)
  )
  (method teardown () (restore-correct-gensym))
)

(test-suite Hash_Syntax
  ; Test helper macro in addition to the full (hash ...) macro
  ; Don't use (hash-add-elements) in your code
  (test hash_add_elements
    (assert        (hash-add-elements foo ())
     macroexpands: (do)
    )
    (assert        (hash-add-elements foo (dfl))
     macroexpands: (send foo 'default= dfl)
    )
    (assert        (hash-add-elements foo (a: 100))
     macroexpands: (send foo 'set 'a 100)
    )
    (assert        (hash-add-elements foo (a: 100 b: 200))
     macroexpands: (do
                     (send foo 'set 'a 100)
                     (send foo 'set 'b 200)
                    )
    )
    (assert        (hash-add-elements foo (a: 100 b: 200 300))
     macroexpands: (do
                     (send foo 'set 'a 100)
                     (do
                       (send foo 'set 'b 200)
                       (send foo 'default= 300)
                     )
                   )
    )
  )
  (test hash
    (start-readable-gensym)
    (assert        (hash)
     macroexpands: (do (let tmp-0 (send Hash 'new)) (do) tmp-0)
    )
    (start-readable-gensym)
    (assert        (hash 5)
     macroexpands: (do (let tmp-0 (send Hash 'new))
                     (send tmp-0 'default= 5)
                    tmp-0)
    )
    (start-readable-gensym)
    (assert        (hash a: 100)
     macroexpands: (do (let tmp-0 (send Hash 'new))
                     (send tmp-0 'set 'a 100)
                    tmp-0)
    )
    (restore-correct-gensym)
  )
  (method teardown () (restore-correct-gensym))
)
