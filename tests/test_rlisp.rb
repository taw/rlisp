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
    full_message = message || "#{expected} expected but was\n#{actual}."
    assert proc{expected.eql?(actual)}, full_message
  end
end

class Test_RLisp < Minitest::Test
  def setup
    @rlisp = RLispCompiler.new
  end

  def assert_runs(code, expected)
    assert_eql(expected, @rlisp.run(RLispGrammar.new(code).expr))
  end

  def run_rlisp(code)
    @rlisp.run(RLispGrammar.new(code).expr)
  end

  def test_constant
    assert_runs("2", 2)
    assert_runs("2.0", 2.0)
    assert_runs("-5.0", -5.0)
    assert_runs("'foo", :foo)
    assert_runs("'(foo bar)", [:foo, :bar])
  end
end

class Test_RLisp_stdlib < Minitest::Test
  def setup
    @rlisp = RLispCompiler.new
    @rlisp.run_file("stdlib.rl")
  end

  def assert_runs(code, expected)
    assert_eql(expected, @rlisp.run(RLispGrammar.new(code).expr))
  end

  def assert_runs_and_equals(code, expected)
    assert_equal(expected, @rlisp.run(RLispGrammar.new(code).expr))
  end

  def run_rlisp(code)
    @rlisp.run(RLispGrammar.new(code).expr)
  end

  def test_hash_key
    assert_runs("(hash-key 'foo:)", :foo)
    assert_runs("(hash-key 'bar:)", :bar)
    assert_runs("(hash-key 'xyzzy:)", :xyzzy)
  end


  def test_hash_oo
    assert_runs_and_equals("[Hash new]", {})
    assert_runs_and_equals("(let h [Hash new])", {})
    assert_runs_and_equals("[h set 'a 100])", 100)
    assert_runs_and_equals("h", {:a => 100})
    assert_runs_and_equals("[h set 'b 200])", 200)
    assert_runs_and_equals("h", {:a => 100, :b => 200})
  end
  def test_hash_macro
    assert_runs_and_equals("(hash)", {})
    assert_runs_and_equals("(hash foo: 1)", {
       :foo => 1
    })
    assert_runs_and_equals("(hash foo: 1  bar: '(1 2 3))", {
       :foo => 1, :bar => [1, 2, 3]
    })
    assert_runs_and_equals("(hash 'foo => 1 'bar => '(1 2 3))", {
       :foo => 1, :bar => [1, 2, 3]
    })
    assert_runs_and_equals("(hash \"foo\" => 1 5 => \"bar\")", {
       "foo" => 1, 5 => "bar"
    })
  end

  def test_arithmetics
    assert_runs("(+ 1)", 1)
    assert_runs("(+ 1 2)", 1+2)
    assert_runs("(+ 1 2 4)", 1+2+4)
    assert_runs("(- 1)", -1)
    assert_runs("(- 1 5)", 1-5)
    assert_runs("(- 1 5 20)", 1-5-20)
    assert_runs("(* 2)", 2)
    assert_runs("(* 2 5)", 2*5)
    assert_runs("(* 2 5 13)", 2*5*13)
  end

  def test_let
    assert_runs("(let x 2)", 2)
    assert_runs("(let y 5)", 5)
    assert_runs("x", 2)
    assert_runs("y", 5)
    assert_runs("(+ x y)", 2+5)
  end

  def test_quasiquote
    assert_runs("`((+ 1 2) ,(+ 1 2) (+ 1 2) ,@'(1 2))", [[:+, 1, 2], 3, [:+, 1, 2], 1, 2])
  end

  def test_double
    run_rlisp("(let double (fn (x) (* x 2)))")
    assert_runs("(double 5)", 10)
    assert_runs("(double 11.0)", 22.0)
  end

  def test_compare
    assert_runs("(< 1 2)", 1 < 2)
    assert_runs("(< 1 1)", 1 < 1)
    assert_runs("(< 2 1)", 2 < 1)

    assert_runs("(<= 1 2)", 1 <= 2)
    assert_runs("(<= 1 1)", 1 <= 1)
    assert_runs("(<= 2 1)", 2 <= 1)

    assert_runs("(> 1 2)", 1 > 2)
    assert_runs("(> 1 1)", 1 > 1)
    assert_runs("(> 2 1)", 2 > 1)

    assert_runs("(>= 1 2)", 1 >= 2)
    assert_runs("(>= 1 1)", 1 >= 1)
    assert_runs("(>= 2 1)", 2 >= 1)
  end

  def test_eql
    assert_runs("(== 1 2)", 1 == 2)
    assert_runs("(== 1 1)", 1 == 1)
    assert_runs("(== 1 1.0)", 1 == 1.0)

    assert_runs("(eql? 1 2)", 1.eql?(2))
    assert_runs("(eql? 1 1)", 1.eql?(1))
    assert_runs("(eql? 1 1.0)", 1.equal?(1.0))
  end

  def test_map
    assert_runs("(map (fn (x) (* x 2)) '(1 2 5))", [2, 4, 10])
  end

  def test_fib
    run_rlisp("(let fib (fn (x)
      (if (< x 2)
        1
        (+ (fib (- x 1)) (fib (- x 2)))
      )
    ))")
    assert_runs("(fib 0)",  1)
    assert_runs("(fib 1)",  1)
    assert_runs("(fib 2)",  2)
    assert_runs("(fib 3)",  3)
    assert_runs("(fib 4)",  5)
    assert_runs("(fib 5)",  8)
    assert_runs("(fib 6)", 13)
    assert_runs("(fib 7)", 21)
    assert_runs("(fib 8)", 34)
    assert_runs("(fib 9)", 55)
    assert_runs("(fib 10)",89)
  end

  def test_sendi
    assert_runs("['(3 7) map & (fn (x) (* x 5))]", [15, 35])
  end

  def test_make_counter
    run_rlisp('(let make-counter (fn (val)
      (fn (incr)
        (let old val)
        (set! val (+ val incr))
        old
      )
    ))')
    run_rlisp("(let counter (make-counter 5))")
    # Counter in 5
    assert_runs("(counter 2)", 5)
    # Counter is 7
    assert_runs("(counter 10)", 7)
    # Counter is 17
    assert_runs("(counter 2)", 17)
    # Counter is 19
    assert_runs("(counter 8)", 19)
    # Counter is 27
    assert_runs("(counter 0)", 27)
  end

  def test_complex
    run_rlisp('(ruby-require "complex")')
    # The interface changed, and there's no way to be compatible with both 1.8's #new == 1.9's #rect
    if RUBY_VERSION < '1.9'
      assert_runs("(let a [Complex new 1.0 2.0])", Complex.new(1.0, 2.0))
      assert_runs("(let b [Complex new 5.0 -1.0])", Complex.new(5.0, -1.0))
      assert_runs("(+ a b)", Complex.new(6.0, 1.0))
    else
      assert_runs("(let a [Complex rect 1.0 2.0])", Complex.rect(1.0, 2.0))
      assert_runs("(let b [Complex rect 5.0 -1.0])", Complex.rect(5.0, -1.0))
      assert_runs("(+ a b)", Complex.rect(6.0, 1.0))
    end
  end

  # Proc.new{|a,*b| a}.call([1, 2, 3]) => 1, not [1, 2, 3]
  def test_arguments_not_mutilated
    assert_runs("((fn (a . b) a) 'foo)", :foo)
    assert_runs("((fn (a . b) a) '(1 2 3))", [1, 2, 3])
    assert_runs("((fn (a . b) a) 1 2 3)", 1)
    assert_runs("((fn (a . b) b) '(1 2 3))", [])
    assert_runs("((fn (a . b) b) 1 2 3)", [2, 3])
  end

  def test_method
    run_rlisp("(class Object
      (method shifted-object-id (x)
        (+ x [self object_id])
      )
    )")
    assert_runs("['foo object_id]", :foo.object_id)
    assert_runs("['foo shifted-object-id 1000]", :foo.object_id + 1000)
  end

  def test_string_add
    assert_runs(%q<(+ "Hello, " "world")>, "Hello, world")
  end

  def test_str
    assert_runs('(str "foo" 15 \'bar)', "foo15bar")
    assert_runs('(str "foo: " \'(1  2   3))', "foo: (1 2 3)")
  end

  def test_rx
    assert_runs('(rx "\\\\d*")', /\d*/)
    assert_runs('(rx "(?i:abc)")', /(?i:abc)/)
  end

  def test_class_foo
    run_rlisp("(let Foo [Class new])")
    run_rlisp(%q<(class Foo
      (attr-accessor 'x 'y)
      (method initialize (x y)
        [self x= x]
        [self y= y]
      )
      (method to_s ()
        (+ "<" [[self x] to_s] "," [[self y] to_s] ">")
      )
    )>)
    assert_runs("[[Foo new 1 2] to_s]", "<1,2>")
  end

  def test_match_arith
    run_rlisp "(defun arithmetics (expr)
      (match expr
      (x 'plus y)  (+ (arithmetics x) (arithmetics y))
      (x 'minus y) (- (arithmetics x) (arithmetics y))
      (x 'times y) (* (arithmetics x) (arithmetics y))
      (x 'div y)   (divide (arithmetics x) (arithmetics y))
      z z
      )
    )"
    assert_runs("(arithmetics 3.0)", 3.0)
    assert_runs("(arithmetics '5.0)", 5.0)
    assert_runs("(arithmetics '(1 plus 2))", 3)
    assert_runs("(arithmetics '((3 times 4) plus 5))", 3*4+5)
  end

  def test_match_arith_macro
    run_rlisp "(defmacro arithmetics (expr)
      (match expr
      (x 'plus y)  `(+ (arithmetics ,x) (arithmetics ,y))
      (x 'minus y) `(- (arithmetics ,x) (arithmetics ,y))
      (x 'times y) `(* (arithmetics ,x) (arithmetics ,y))
      (x 'div y)   `(divide (arithmetics ,x) (arithmetics ,y))
      z z
      )
    )"
    assert_runs("(arithmetics 5.0)", 5.0)
    assert_runs("(arithmetics (1 plus 2))", 3)
    assert_runs("(arithmetics ((3 times 4) plus 5))", 3*4+5)
  end

  def test_get_set_symbols
    assert_runs('[(list "x" "y" "z") [] 1]', "y")
    assert_runs('(do (let a (list "x" "y" "z")) [a []= 1 "v"] a)', ["x", "v", "z"])
  end
end

class Test_RLisp_macros < Minitest::Test
  def setup
    @rlisp = RLispCompiler.new
  end

  def assert_runs(code, expected)
    assert_eql(expected, @rlisp.run(RLispGrammar.new(code).expr))
  end

  def assert_macroexpands(code, expected)
    res = @rlisp.precompile(RLispGrammar.new(code).expr)
    expected = RLispGrammar.new(expected).expr
    assert_eql(expected, res)
  end

  def run_rlisp(code)
    @rlisp.run(RLispGrammar.new(code).expr)
  end

  def test_defun
    run_rlisp("(letmacro defmacro (fn (name args . body) `(letmacro ,name (fn ,args ,@body))))")
    run_rlisp("(defmacro my-defun (name args . code)
      `(let ,name (fn ,args ,@code))
    )")
    assert_macroexpands("(my-defun double (x) (* x 2))", "(let double (fn (x) (* x 2)))")
  end

  def test_hash_vm
    @rlisp.run_file("stdlib.rl")
    # Make gensym symbols printable
    $gensym = 0
    run_rlisp "(defun gensym ()
       (ruby-eval \"$gensym||=0; $gensym+=1; ('tmp-' + $gensym.to_s).to_sym\")
    )"
    assert_macroexpands("(hash a: 100 b: 200)",
    "(do
      (let tmp-1 (send Hash 'new))
      (do
        (send tmp-1 'set 'a 100)
        (send tmp-1 'set 'b 200)
      )
      tmp-1
    )")
  end

  def test_match
    @rlisp.run_file("stdlib.rl")
    # Make gensym symbols printable
    $gensym = 0
    run_rlisp "(defun gensym ()
       (ruby-eval \"$gensym||=0; $gensym+=1; ('tmp-' + $gensym.to_s).to_sym\")
    )"

    tmp = "tmp-1"
    assert_macroexpands("(match (x)
      'foo (one)
      'bar two
      (three)
    )", "
    (do
      (let #{tmp} (x))
      (if (send #{tmp} '== 'foo)
      (one)
      (if (send #{tmp} '== 'bar)
        two
        (three)
      )
      )
    )")

    tmp = "tmp-2"
    assert_macroexpands("(match (x)
      0 (one)
      1.0 (two)
      \"foo\" (three)
      y (f y)
    )", "
    (do
      (let #{tmp} (x))
      (if (send #{tmp} '== 0)
      (one)
      (if (send #{tmp} '== 1.0)
        (two)
        (if (send #{tmp} '== \"foo\")
        (three)
        (if (do (let y #{tmp}) true)
          (f y)
          nil
        )
        )
      )
      )
    )")
  end
  def test_bool_and
    @rlisp.run_file("stdlib.rl")
    assert_macroexpands("(bool-and a b c)","
      (if a (if b c false) false)
    ")
  end

  def test_match_2
    @rlisp.run_file("stdlib.rl")
    # Make gensym symbols printable
    $gensym = 0
    run_rlisp "(defun gensym ()
       (ruby-eval \"$gensym||=0; $gensym+=1; ('tmp-' + $gensym.to_s).to_sym\")
    )"
    tmp   = "tmp-1"
    tmp_a = "tmp-2"
    tmp_b = "tmp-3"
    tmp_c = "tmp-4"
    assert_macroexpands("(match (x)
      () (one)
      ('x y 'z) (two)
      (three)
    )", "(do
      (let #{tmp} (x))
      (if (send #{tmp} '== ())
      (one)
      (if
        (if
        (send #{tmp} 'is_a? Array)
        (if
          (send (send #{tmp} 'size) '== 3)
          (if (do
            (let #{tmp_a} (send #{tmp} 'get 0))
            (send #{tmp_a} '== 'x)
          )
          (if (do
            (let #{tmp_b} (send #{tmp} 'get 1))
            (do
            (let y #{tmp_b})
            true
            ))
            (do
            (let #{tmp_c} (send #{tmp} 'get 2))
            (send #{tmp_c} '== 'z)
            )
            false
          )
          false
          )
          false
        )
        false
        )
        (two)
        (three)
      )
      )
    )")
  end
end

class Test_Backtraces < Minitest::Test
  def setup
    @rlisp = RLispCompiler.new
    @rlisp.run_file("stdlib.rl")
  end

  def assert_backtrace(code, expected)
    begin
      @rlisp.run(RLispGrammar.new(code).expr, "example.rl")
    rescue Exception => e
      bt = e.backtrace
      # A lot of these are due to 1.8 vs 1.9 differences
      bt = bt.select{|line|
        line !~ %r[test/unit|src/rlisp\.rb|test_all\.rb|test_rlisp\.rb|`\[\]'|`call'|`default'|`yield'|lib/minitest]
      }.map{|line| line.sub("block in ", "")}
      assert_equal(expected, bt, <<EOF)
Full backtrace:
#{e}
#{bt.join "\n"}
EOF
      return
    end
    flunk "#{code.inspect_lisp} was supposed to raise an exception"
  end

  def test_fn_bt
    # Why not example.rl:3 ?
    assert_backtrace("(do
       (let foo (fn ()
        (bar)
       ))
       (foo)
    )", ["example.rl:2:in `foo'", "example.rl:5:in `run'"])
  end

  def test_local_fn_bt
    # Why not example.rl:3 ?
    assert_backtrace("(local
       (let foo (fn ()
        (bar)
       ))
       (foo)
    )", ["example.rl:2:in `foo'", "example.rl:5:in `anon_fn'", "example.rl:5:in `run'"])
  end

  def test_defun_bt
    # Why not example.rl:3 ?
    assert_backtrace("(do
       (defun foo ()
        (bar)
       )
       (foo)
    )", ["example.rl:2:in `foo'", "example.rl:5:in `run'"])
  end

  def test_local_defun_bt
    # Why not example.rl:3 ?
    assert_backtrace("(local
       (defun foo ()
        (bar)
       )
       (foo)
    )", ["example.rl:2:in `foo'", "example.rl:5:in `anon_fn'", "example.rl:5:in `run'"])
  end

  def test_nested_bt
    assert_backtrace("(print (foo))", ["example.rl:1:in `run'"])
    assert_backtrace("(print
      (foo)
    )", ["example.rl:2:in `run'"])
  end

  def test_simple_bt
    assert_backtrace("NoSuchGlobal", ["example.rl:1:in `run'"])
    assert_backtrace("(foo)", ["example.rl:1:in `run'"])
    assert_backtrace("(
    foo
    )", ["example.rl:1:in `run'"])
    assert_backtrace("
    (foo)
    ", ["example.rl:2:in `run'"])
  end
  def test_method_bt
    # It used to work better in 1.8 apparently
    assert_backtrace("(do (class Object
      (method a_test_method ()
        (raise \"NoHope\")
      )
    )
    [self a_test_method]
    )", ["example.rl:2:in `anon_fn_1'", "example.rl:6:in `run'"])
  end
end
