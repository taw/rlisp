(require "rlunit.rl")

(test-suite Variables
  (test ivar
    (let obj [Object new])
    
    (assert [obj instance_eval & (fn () @foo)] == nil)
    [obj instance_eval & (fn () (let @foo 5))]
    (assert ((ruby-eval "lambda{|x| x.instance_eval{@foo}}") obj) == 5)
    (assert [obj instance_eval & (fn () @foo)] == 5)

    [obj instance_eval & (fn () (set! @bar 5))]
    (assert ((ruby-eval "lambda{|x| x.instance_eval{@bar}}") obj) == 5)
    (assert [obj instance_eval & (fn () @bar)] == 5)
  )
  (test gvar
    (ruby-eval "$a_magic_variable = 42")
    (assert $a_magic_variable == 42)

    (ruby-eval "$a_magic_variable = 51")
    (assert $a_magic_variable == 51)

    (let $a_magic_variable 24)
    (assert $a_magic_variable == 24)
    (assert (ruby-eval "$a_magic_variable") == 24)

    (set! $a_magic_variable 33)
    (assert $a_magic_variable == 33)
    (assert (ruby-eval "$a_magic_variable") == 33)
  )

; cvars will *not* work for implementation reasons
; Their semantics are pretty ugly, so it's best to forget about them anyway.
;  (test cvar
;    (let obj [Class new])
;    
;    (assert [obj instance_eval & (fn () @@foo)] == nil)
;    [obj instance_eval & (fn () (let @@foo 5))]
;    (assert ((ruby-eval "lambda{|x| x.instance_eval{@@foo}}") obj) == 5)
;    (assert [obj instance_eval & (fn () @@foo)] == 5)
;
;    [obj instance_eval & (fn () (set! @@bar 5))]
;    (assert ((ruby-eval "lambda{|x| x.instance_eval{@@bar}}") obj) == 5)
;    (assert [obj instance_eval & (fn () @@bar)] == 5)
;  )
)
