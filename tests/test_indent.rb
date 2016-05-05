#!/usr/bin/env ruby

require "minitest/autorun"
require 'rlisp_indent'

class Test_Indent < Minitest::Test
  def assert_indent(code_out,code_in)
    assert_equal(code_out,RLispIndent.indent(code_in))
  end
  def test_indent
    assert_indent(<<OUT, <<IN)
(let a (+ 1 2))

(let b (+ 3 4))
OUT
(let a (+ 1 2))

(let b (+ 3 4))
IN

    assert_indent(<<OUT, <<IN)
(let a
  (+ 1 2))
(let b
  (+ 3 4))
OUT
(let a
(+ 1 2))
(let b
    (+ 3 4))
IN

    assert_indent(<<OUT, <<IN)
(let a
  (+ 1 2)
)
(let b
  (+ 3 4)
)
OUT
(let a
(+ 1 2)
)
(let b
  (+ 3 4)
  )
IN

    assert_indent(<<OUT, <<IN)
(if a (if b (if c (if d
        x
        y)
      z)
    v)
  u)
OUT
(if a (if b (if c (if d
x
y)
z)
v)
u)
IN

    assert_indent(<<OUT, <<IN)
(if a (if b (if c (if d
  x y) z) v) u)
OUT
(if a (if b (if c (if d
x y) z) v) u)
IN

    assert_indent(<<OUT, <<IN)
(if a (if b (if c (if d
        x
      )
    )
  )
)
OUT
(if a (if b (if c (if d
x
)
)
)
)
IN

    assert_indent(<<OUT, <<IN)
(if a (if b (if c (if d
    x
  ))
))
OUT
(if a (if b (if c (if d
x
))
))
IN

    assert_indent(<<OUT, <<IN)
(foo a [x + (foo b [y +
    z])
  v])
OUT
(foo a [x + (foo b [y +
z])
v])
IN

    assert_indent(<<OUT, <<IN)
(foo a [x + (foo b [y +
  z])
])
OUT
(foo a [x + (foo b [y +
z])
])
IN
  end
end
