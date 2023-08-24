#!/usr/bin/env ruby

require "minitest/autorun"
require 'rlisp'

class Test_RLisp_support < Minitest::Test
  def test_variable
    a = Variable.new
    assert_nil(a.get)
    a.set "foo"
    assert_equal("foo", a.get)
    a.set "bar"
    assert_equal("bar", a.get)
  end

  def test_to_s_lisp
    cases = [
      [0, "0"],
      [0.0, "0.0"],
      [12345678901234567890, "12345678901234567890"],
      [5, "5"],
      [5.0, "5.0"],
      [-5, "-5"],
      [-5.0, "-5.0"],
      [nil, "nil"],
      [true, "true"],
      [false, "false"],
      [:foo, "foo"],
      ["foo", 'foo'],
      [[], "()"],
      [[1,2,3], "(1 2 3)"],
      [[[],[2],["foo", "bar"]], "(() (2) (foo bar))"],
    ]
    cases.each{|obj, expected|
      assert_equal(expected, obj.to_s_lisp)
    }
  end
  # The only major difference between to_s_lisp and inspect_lisp
  # is printing strings.
  # There's simply no way to get a single reasonable behaviour:
  # (print "Hello, world!") must print:
  #   Hello, world! (no quotes)
  # While
  # repl> (+ "Hello, " "world!")
  # must print
  # "Hello, world!" (with quotes)
  #
  # Everything else has a reasonable one way of getting printed
  def test_inspect_lisp
    cases = [
      [0, "0"],
      [0.0, "0.0"],
      [12345678901234567890, "12345678901234567890"],
      [5, "5"],
      [5.0, "5.0"],
      [-5, "-5"],
      [-5.0, "-5.0"],
      [nil, "nil"],
      [true, "true"],
      [false, "false"],
      [:foo, "foo"],
      ["foo", '"foo"'],
      [[], "()"],
      [[1,2,3], "(1 2 3)"],
      [[[],[2],["foo", "bar"]], '(() (2) ("foo" "bar"))'],
    ]
    cases.each{|obj, expected|
      assert_equal(expected, obj.inspect_lisp)
    }
  end

  def test_get_set
    a = [5, 7]
    assert_equal(5, a.get(0))
    assert_equal(7, a.get(1))
    a.set(1, 9)
    a.set(2, 11)
    assert_equal([5, 9, 11], a)
  end

  def test_symbol_mangle_c
    assert_equal("foo", :foo.mangle_c)
    assert_equal("_3d_3d", :"==".mangle_c)
    assert_equal("_5fx_5fy_5f", :"_x_y_".mangle_c)
  end

  def test_symbol_stringify_c
    assert_equal('"foo"', :foo.stringify_c)
    assert_equal('"=="', :"==".stringify_c)
    assert_equal('"_x_y_"', :"_x_y_".stringify_c)
    assert_equal("\"\\\\\\\"\"", :"\\\"".stringify_c)
  end
end
