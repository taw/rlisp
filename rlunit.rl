(ruby-require "test/unit")
(require "macrobuilder.rl")

; Orded of arguments is reversed compared to Ruby test/unit,
; and actual goes before expected.
; (assert obj kind_of? Array)
; vs
; assert_kind_of(Array, obj)

(pattern-macro-create assert
  ('nil? a)           `[self assert_nil ,a]
  ('nil? a 'msg: msg) `[self assert_nil ,a ,msg]

  (a '=~ b)           `[self assert_match ,b ,a]
  (a '=~ b 'msg: msg) `[self assert_match ,b ,a ,msg]

  (a '!~ b)           `[self assert_no_match ,b ,a]
  (a '!~ b 'msg: msg) `[self assert_no_match ,b ,a ,msg]

  (a '!= b)           `[self assert_not_equal ,b ,a]
  (a '!= b 'msg: msg) `[self assert_not_equal ,b ,a ,msg]

  (a 'same: b)           `[self assert_same ,b ,a]
  (a 'same: b 'msg: msg) `[self assert_same ,b ,a ,msg]
    
  (a 'not-same: b)           `[self assert_not_same ,b ,a]
  (a 'not-same: b 'msg: msg) `[self assert_not_same ,b ,a ,msg]

  (a 'kind-of? b)           `[self assert_kind_of  ,b ,a]
  (a 'kind-of? b 'msg: msg) `[self assert_kind_of  ,b ,a ,msg]

  (a 'instance-of? b)          `[self assert_instance_of  ,b ,a]
  (a 'instance-of? b msg: msg) `[self assert_instance_of  ,b ,a ,msg]

  ('block: blk)                `[self assert_block & (fn () ,@blk)]
  ('block: blk 'msg: msg)      `[self assert_block ,msg & (fn () ,@blk)]
  ('msg: msg 'block: blk)      `[self assert_block ,msg & (fn () ,@blk)]

  (a '== b 'delta: c) `[self assert_in_delta  ,b ,a ,c]
  (a '== b 'delta: c
         'msg: msg)   `[self assert_in_delta  ,b ,a ,c ,msg]
  (a '== b 'msg: msg
         'delta: c)   `[self assert_in_delta  ,b ,a ,c ,msg]


  (a '== b)           `[self assert_equal ,b ,a]
  (a '== b 'msg: msg) `[self assert_equal ,b ,a ,msg]
    
  (a 'macroexpands: b) `(assert (macroexpand-rec ',a) == ',b)
  (a 'macroexpands: b
     'msg: msg)        `(assert (macroexpand-rec ',a) == ',b msg: ,msg)
    
  (a b)             `[self assert_equal ,b ,a]
  (a b 'msg: msg)   `[self assert_equal ,b ,a ,msg]
  (a)               `[self assert ,a]
  (a 'msg: msg)     `[self assert ,a ,msg]

  (raise SyntaxError [(cons 'assert args) inspect_lisp])
)
(pattern-macro-recompile assert)

(defmacro test (name . body)
   (let test_name [(str "test_" name) to_sym])
   `(method ,test_name () ,@body))

(defmacro test-suite (name . body)
  (let class_name [(str "Test_" name) to_sym])
  `(do
    (let ,class_name [Class new Test::Unit::TestCase])
    (class ,class_name
      ,@body)))
