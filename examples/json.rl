(ruby-require "rubygems")
(ruby-require "json")

(let rlisp-value (list
   1 2 "foo" (hash
     hello: 42
     world: 56
   )
))

(let json-value [rlisp-value to_json])

(print "Original value:")
(print [rlisp-value inspect_lisp])
(print "As JSON:")
(print json-value)
(print "Parsed back:")
(print [[JSON parse json-value] inspect_lisp])
