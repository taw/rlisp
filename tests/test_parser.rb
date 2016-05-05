#!/usr/bin/env ruby

require "minitest/autorun"
require 'rlisp'

##
# Passes if +expected+.eql?(+actual).
#
# Note that the ordering of arguments is important, since a helpful
# error message is generated when this one fails that tells you the
# values of expected and actual.
#
# Example:
#   assert_eql 'MY STRING', 'my string'.upcase
#   assert_eql 1.0, 1 # fails
module Minitest::Assertions
  public
  def assert_eql(expected, actual, message=nil)
    full_message = build_message(message, <<EOT, expected, actual)
<?> expected but was
<?>.
EOT
    assert_block(full_message) { expected.eql?(actual) }
  end
end

class Test_Parser < Minitest::Test
  def assert_parses(rlisp, ast)
    assert_eql(ast, RLispGrammar.new(rlisp).expr)
  end
  def test_symbols
    assert_parses("a", :a)
    assert_parses("A", :A)
    assert_parses("foo-bar", :"foo-bar")
    assert_parses("az_AZ09!", :"az_AZ09!")
    assert_parses("_a?", :"_a?")
    assert_parses("[]", :[])
    assert_parses("[]=", :[]=)
  end
  def test_numbers
    assert_parses("1", 1)
    assert_parses("1.0", 1.0)
    assert_parses("-1", -1)
    assert_parses("-1.0", -1.0)
    assert_parses("(1 1.0 -1 -1.0 0 0.0 -0 -0.0)", [1, 1.0, -1, -1.0, 0, 0.0, -0, -0.0])
  end
  def test_lists
    assert_parses("()", [])
    assert_parses("(a)", [:a])
    assert_parses("(a b)", [:a, :b])
    assert_parses("((a) (b) (c))", [[:a], [:b], [:c]])
    assert_parses("((((()))) ((())) (()) ())", [[[[[]]]], [[[]]], [[]], []])
  end
  def test_reader_macros
    assert_parses("'a", [:quote, :a])
    assert_parses("[a b c]", [:send, :a, [:quote, :b], :c])
    assert_parses("`a", [:quasiquote, :a])
    assert_parses(",a", [:unquote, :a])
    assert_parses(",@a", [:"unquote-splicing", :a])
  end
  def test_strings
    assert_parses('""', "")
    assert_parses('"foo"', "foo")
    assert_parses('"foo \\" bar"', "foo \" bar")
    assert_parses(%Q["\\\\\\r\\n"], "\\\r\n")
  end
end

class Test_Debug_Info < Minitest::Test
  def test_debug_info
    fh = File.open("tests/adder.rl")
    parser = RLispGrammar.new(fh, "tests/adder.rl")
    assert_eql(["tests/adder.rl", 1, 0], parser.expr.debug_info)
    assert_eql(["tests/adder.rl", 4, 0], parser.expr.debug_info)
    assert_eql(["tests/adder.rl", 5, 0], parser.expr.debug_info)
    assert_eql(["tests/adder.rl", 6, 0], parser.expr.debug_info)
    assert_eql(["tests/adder.rl", 7, 0], parser.expr.debug_info)
  end
  def test_debug_info_precompile
    code = "(let foo (fn () (bar)))"
    parser = RLispGrammar.new(code)
    expr = parser.expr
    assert_eql(["example.rl", 1, 0], expr.debug_info)
    assert_eql(["example.rl", 1, 9], expr[2].debug_info)
    assert_eql(["example.rl", 1, 16], expr[2][2].debug_info)

    rlisp = RLispCompiler.new
    pexpr = rlisp.precompile(expr)
    assert_eql(["example.rl", 1, 0], pexpr.debug_info)
    assert_eql(["example.rl", 1, 9, :foo], pexpr[2].debug_info)
    assert_eql(["example.rl", 1, 16, :foo], pexpr[2][2].debug_info)
  end
  def test_debug_info_defun
    code = "(defun foo () (bar))"
    parser = RLispGrammar.new(code)
    expr = parser.expr
    assert_eql(["example.rl", 1, 0], expr.debug_info)
    assert_eql(["example.rl", 1, 14], expr[3].debug_info)

    rlisp = RLispCompiler.new
    rlisp.run_file('stdlib.rl')
    pexpr = rlisp.precompile(expr)
    assert_eql(["example.rl", 1, 0], pexpr.debug_info)
    assert_eql(["example.rl", 1, 0, :foo], pexpr[2].debug_info)
    assert_eql(["example.rl", 1, 14, :foo], pexpr[2][2].debug_info)
  end
end
