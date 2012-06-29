(ruby-require "yaml")

(let rlisp-value (list
   1 2 "foo" (hash
     hello: 42
     world: 56
   )
))

(let yaml-value [rlisp-value to_yaml])

(print "Original value:")
(print [rlisp-value inspect_lisp])
(print "As YAML:")
(print yaml-value)
(print "Parsed back:")
(print [[YAML load yaml-value] inspect_lisp])
