(require "rlunit.rl")

(test-suite RLUnitExample
  (test example
    (assert 9 == (+ 2 7))
    (assert 2 == (- 6 4))
    (assert 2 == (- 6 4) msg: "Subtraction should work")
    (assert 96 == (* 8 4 3))
    (assert nil? nil)
    (assert true)
    (assert (> 3 2))
    (assert msg: "assert_block failed" block: (true))
    (assert (not (== 3 7)))
    (assert 1.99 == 2.02 delta: 0.05 msg: "Deviation is too high")
    (assert '() instance-of? Array)
    (assert '(foo bar) instance-of? Array)
    (assert '(foo bar) kind-of? Enumerable)
    (assert "Foo" =~ (rx "(?i:foo)"))
    (assert "123" =~ (rx "\\d+"))
    (assert "Ruby 2.0" =~ (rx "\\d+\\.\\d+"))
    (assert "Ruby 2.0" !~ (rx "\\A\\d+\\.\\d+\\Z"))
    (assert "3.14159" =~ (rx "\\d+\\.\\d+"))
    (assert "3.14159" =~ (rx "\\A\\d+\\.\\d+\\Z"))
    (assert () != nil)
    (assert #f same: false)
    (assert #t same: true)
  )
)
