(require "rlunit.rl")

(pattern-macro-extend assert
  (rlisp 'syntax: ruby)     `(assert ,rlisp == (ruby-eval ,ruby))
  (rlisp 'not-syntax: ruby) `(assert ,rlisp != (ruby-eval ,ruby))
)
(pattern-macro-recompile assert)

(test-suite Syntax
  (test true_class
    (assert true     syntax: "true")
    (assert #t       syntax: "true")
    (assert 't   not-syntax: "true")
  )
  (test false_class
    (assert false     syntax: "false")
    (assert #f        syntax: "false")
    (assert nil   not-syntax: "false")
    (assert ()    not-syntax: "false")
  )
  (test nil_class
    (assert nil     syntax: "nil")
    (assert ()  not-syntax: "nil")
  )
  (test integer
    (assert                     0 syntax: "0")
    (assert                    -0 syntax: "-0")
    (assert                     5 syntax: "5")
    (assert                    -5 syntax: "-5")
    (assert  12345678901234567890 syntax: "12345678901234567890")
    (assert -12345678901234567890 syntax: "-12345678901234567890")
    (assert                0x1234 syntax: "0x1234")
    (assert               -0x1234 syntax: "-0x1234")
    (assert                  0755 syntax: "0755")
    (assert                 -0755 syntax: "-0755")
    (assert                 0o755 syntax: "0o755")
    (assert                -0o755 syntax: "-0o755")
    (assert               0b10011 syntax: "0b10011")
    (assert              -0b10011 syntax: "-0b10011")
  )
  (test float
    (assert       0.0 syntax: "0.0")
    (assert      -0.0 syntax: "-0.0")
    (assert       5.0 syntax: "5.0")
    (assert      -5.0 syntax: "-5.0")
    (assert      3.14 syntax: "3.14")
    (assert     -3.14 syntax: "-3.14")
    (assert       1e6 syntax: "1e6")
    (assert      -1e6 syntax: "-1e6")
    (assert   1.234e6 syntax: "1.234e6")
    (assert  -1.234e6 syntax: "-1.234e6")
    (assert  1.234e+6 syntax: "1.234e+6")
    (assert -1.234e+6 syntax: "-1.234e+6")
    (assert  1.234e-6 syntax: "1.234e-6")
    (assert -1.234e-6 syntax: "-1.234e-6")
    ; TODO: Syntax for +-infinity and nan
  )
  (test array
    (assert                        () syntax: "[]")
    (assert              (list 1 2 3) syntax: "[1, 2, 3]")
    (assert                  '(1 2 3) syntax: "[1, 2, 3]")
    (assert                  `(1 2 3) syntax: "[1, 2, 3]")
    (assert           `(1 ,(+ 2 3) 6) syntax: "[1, 2+3, 6]")
    (assert     `(1 2 ,@(list 3 4 5)) syntax: "[1, 2, *[3, 4, 5]]")
    (assert (list 1 2 . (list 3 4 5)) syntax: "[1, 2, *[3, 4, 5]]")
  )
  (test range
    (assert       [Range new 1 25]      syntax: "1..25")
    (assert [Range new 2 25 false]      syntax: "2..25")
    (assert  [Range new 3 25 true]      syntax: "3...25")
    (assert              (.. 4 25)      syntax: "4..25")
    (assert             (... 5 25)      syntax: "5...25")
    (assert              [6 .. 25]      syntax: "6..25")
    (assert             [7 ... 25]      syntax: "7...25")
    (assert              (... 8 25) not-syntax: "8..25")
    (assert               (.. 9 25) not-syntax: "9...25")
    (assert             [10 ... 25] not-syntax: "10..25")
    (assert              [11 .. 25] not-syntax: "11...25")
  )
  (test symbol
    (assert     'foo     syntax: ":foo")
    (assert     'foo not-syntax: "\"foo\"")
    (assert 'foo-bar     syntax: ":\"foo-bar\"")
    (assert    '@foo     syntax: ":@foo")
    (assert 'foo?!?!     syntax: ":\"foo?!?!\"")
  )
  (test hash
    (assert                       (hash) syntax: "{}")
    (assert         (hash 1 => 2 3 => 4) syntax: "{1 => 2, 3 => 4}")
    (assert (hash 'foo => 42 'bar => 96) syntax: "{:foo => 42, :bar => 96}")
    (assert       (hash foo: 42 bar: 96) syntax: "{:foo => 42, :bar => 96}")
  )
  (test time
    (assert [Time at 1178573823] syntax: "Time.at(1178573823)")
    ; There's no guarantee that these two will be equal
    ;(assert [Time now] syntax: "Time.now")
  )
  (test string
    (assert                  "Hello" syntax: "'Hello'")
    (assert        "Hello, world!\n" syntax: "\"Hello, world!\\n\"")
    (assert (str "2 + 2 = " (+ 2 2)) syntax: "\"2 + 2 = \#{2 + 2}\"")
    (assert                     "#x" syntax: "\"#x\"") ; "#"
    (assert                      "#" syntax: "\"#\"") ; "#"
    (assert                    "#\n" syntax: "\"#\\n\"") ; "#\n"
    (assert                   "#\\n" syntax: "\"#\\\\n\"") ; "#\\n"
    (assert                   "\#{}" syntax: "\"\\\#{}\"") ; '#{}'
    (assert            "##{(+ 1 2)}" syntax: "\"#\#{1+2}\"") ; '#3'
    (assert     "2 + 2 = #{(+ 2 2)}" syntax: "\"2 + 2 = \#{2 + 2}\"")
    (assert    "2 + 2 = #{'(1 2 3)}" syntax: "\"2 + 2 = \#{[1, 2, 3].to_s_lisp}\"")
  )
  (test regexp
    (assert      (rx "foo") syntax: "/foo/")
    (assert (rx "(?i:foo)") syntax: "/(?i:foo)/") ; /foo/i
    (assert     (rx "\\d+") syntax: "/\\d+/") ; /\d+/
    (assert           /\d+/ syntax: "/\\d+/") ; /\d+/
    (assert          /foo/i syntax: "/foo/i")
  )
)

; Standard library classes without tests:
; * Binding
; * Class
; * Continuation
; * Data
; * Dir
; * File
; * File::Stat
; * IO
; * MatchData
; * Method
; * Module
; * NameError::message
; * Object
; * Proc
; * Process::Status
; * Struct
; * Struct::Tms
; * Thread
; * ThreadGroup
; * UnboundMethod
