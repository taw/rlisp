; Library for building macros from pieces

(let pattern-macros-db (hash))

(defmacro pattern-macro-recompile (name)
  `(defmacro ,name args
    (match args ,@[pattern-macros-db get name])
  )
)

(defmacro pattern-macro-create (name . patterns)
  `[pattern-macros-db set ',name ',patterns]
)

(defmacro pattern-macro-extend (name . patterns)
  `[pattern-macros-db set ',name
    [',patterns + [pattern-macros-db get ',name]]
  ]
)

;(pattern-macro-create my-assert
;  (raise SyntaxError [(cons 'my-assert args) inspect_lisp])
;)
;(pattern-macro-extend my-assert
;  ('nil? a 'msg: msg) `[self assert_nil ,a ,msg]
;  ('nil? a) `[self assert_nil ,a]
;)
;(print (macroexpand-rec '(my-assert nil? foo)))
