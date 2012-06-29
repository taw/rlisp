(ruby-require "test/unit")

(let Test_testing_framework [Class new Test::Unit::TestCase])
(class Test_testing_framework
  (method test_assertions ()
    [self assert_equal 9 (+ 2 7)]
    [self assert_equal 2 (- 6 4)]
    [self assert_equal 96 (* 8 4 3)]
    [self assert_nil nil]
    [self assert true]
    [self assert (> 3 2)]
    [self assert_block "assert_block failed" & (fn () true)]
    [self assert (not (== 3 7))]
    [self assert_in_delta 1.99 2.02 0.05 "Deviation is too high"]
    [self assert_instance_of Array ()]
    [self assert_instance_of Array '(foo bar)]
    [self assert_kind_of Enumerable '(foo bar)]
    [self assert_match (rx "(?i:foo)") "Foo"]
    [self assert_match (rx "\\d+") "123"]
    [self assert_match (rx "\\d+\\.\\d+") "Ruby 2.0"]
    [self assert_no_match (rx "\\A\\d+\\.\\d+\\Z") "Ruby 2.0"]
    [self assert_match (rx "\\d+\\.\\d+") "3.14159"]
    [self assert_match (rx "\\A\\d+\\.\\d+\\Z") "3.14159"]
    [self assert_not_equal () nil]
    [self assert_same #f false]
    [self assert_same #t true]
  )
)
