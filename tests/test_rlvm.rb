#!/usr/bin/env ruby

require "minitest/autorun"
require 'rlisp'

class Test_RLVM_Ruby < Minitest::Test
  def assert_compiles(code, expected, test_id)
    expr = RLispGrammar.new(code).expr

    expected = expected.gsub(/^ {4}/, "").sub(/^\n/,"")
    expected = expected.gsub(/^ */, "").gsub(/;/,"\n").chomp
    
    actual = RLispCompiler.new.rlvm_compile(expr, "RLispTestC#{test_id}")
    actual = actual.gsub(/^\n/,"").gsub(/;/,"\n").chomp
    
    full_message = <<EOT
#{expected}

expected but was:
#{actual}
EOT
    assert_block(full_message) { expected == actual }
  end

  def test_constant
    assert_compiles("2", "
    2
    ", 1)

    assert_compiles("2.0", "
    2.0
    ", 2)

    assert_compiles("'foo", "
    :foo
    ", 3)

    assert_compiles("\"foo\"", "
    \"foo\"
    ", 4)
  end
  
  def test_constant_list
    assert_compiles("'(foo bar 5)", "
    t0 = [:foo, :bar, 5]
    t0
    ", 5)
  end

  def test_add
    assert_compiles("(+ 2 3)
    ", "
    t0 = globals[:+]
    t1 = t0.call(2, 3)
    t1
    ", 6)
  end

  def test_if
    assert_compiles("(if (< x 0) x (- x))
    ", "
    t0 = globals[:<]
    t1 = globals[:x]
    t2 = t0.call(t1, 0)
    if t2
      t4 = globals[:x]
      t3 = t4
    else
      t5 = globals[:-]
      t6 = globals[:x]
      t7 = t5.call(t6)
      t3 = t7
    end
    t3
    ", 7)
  end

  def test_global_let
    assert_compiles("(let x 5)
    ", "
    globals[:x] = 5
    5
    ", 8)
  end

  def test_global_set
    assert_compiles("(set! x 5)
    ", "
    globals[:x] = 5
    5
    ", 9)
  end

  def test_local_let
    assert_compiles("(fn (x) (let y 2) (+ x y))
    ", "
    module ::RLispTestC10;def self.anon_fn(globals)
      Proc.new do |*args|
        x, = *args
        y = 2
        t0 = globals[:+]
        t1 = y
        t2 = t0.call(x, t1)
        t2
      end
    end;end
    t3 = ::RLispTestC10::anon_fn(globals)
    t3
    ", 10)
  end

  def test_local_set
    assert_compiles("(fn (x) (set! x (+ x 42)) x)
    ", "
    module ::RLispTestC11;def self.anon_fn(globals)
      Proc.new do |*args|
        x, = *args
        t0 = globals[:+]
        t1 = x
        t2 = t0.call(t1, 42)
        x = t2
        t3 = x
        t3
      end
    end;end
    t4 = ::RLispTestC11::anon_fn(globals)
    t4
    ", 11)
  end

  def test_set_in_fun
    assert_compiles("(fn (x) (set! y x))
    ", "
    module ::RLispTestC12;def self.anon_fn(globals)
      Proc.new do |*args|
        x, = *args
        globals[:y] = x
        x
      end
    end;end
    t0 = ::RLispTestC12::anon_fn(globals)
    t0
    ", 12)
  end

  def test_do
    assert_compiles("(do x y)
    ", "
    t0 = globals[:x]
    t1 = globals[:y]
    t1
    ", 13)
  end

  def test_const_fun
    assert_compiles("(fn args
      (+ 2 40)
    )", "
    module ::RLispTestC14;def self.anon_fn(globals)
      Proc.new do |*args|
        *args = *args
        t0 = globals[:+]
        t1 = t0.call(2, 40)
        t1
      end
    end;end
    t2 = ::RLispTestC14::anon_fn(globals)
    t2
    ", 14)
  end

  def test_double
    assert_compiles("(fn (n)
      (* 2 n)
    )", "
    module ::RLispTestC15;def self.anon_fn(globals)
      Proc.new do |*args|
        n, = *args
        t0 = globals[:*]
        t1 = t0.call(2, n)
        t1
      end
    end;end
    t2 = ::RLispTestC15::anon_fn(globals)
    t2
    ", 15)
  end

  def test_addx
    assert_compiles("(fn (x)
      (fn (y) (+ x y))
    )", "
    module ::RLispTestC16;def self.anon_fn_1(globals, x)
      Proc.new do |*args|
        y, = *args
        t0 = globals[:+]
        t1 = t0.call(x, y)
        t1
      end
    end;end
    module ::RLispTestC16;def self.anon_fn(globals)
      Proc.new do |*args|
        x, = *args
        t2 = ::RLispTestC16::anon_fn_1(globals, x)
        t2
      end
    end;end
    t3 = ::RLispTestC16::anon_fn(globals)
    t3
    ", 16)
  end

  def test_quasiquote
    assert_compiles("`foo",
    "
    :foo
    ", 17)
    assert_compiles("`4.0",
    "
    4.0
    ", 18)
    assert_compiles("`()",
    "
    t0 = []
    t0
    ", 19)
    assert_compiles("`(foo bar)",
    "
    t0 = [:foo, :bar]
    t0
    ", 20)
    assert_compiles("`(foo ,bar)",
    "
    t0 = globals[:bar]
    t1 = [:foo, t0]
    t1
    ", 21)
    assert_compiles("`(foo ,@bar)",
    "
    t0 = globals[:bar]
    t1 = [:foo, *t0]
    t1
    ", 22)
    assert_compiles("`(,@foo bar)",
    "
    t0 = globals[:foo]
    t1 = t0 + [:bar]
    t1
    ", 23)
  end

  def test_rlvm_fib
    assert_compiles("(let fib (fn (x)
      (if (< x 2)
        1
        (+ (fib (- x 1)) (fib (- x 2)))
      )
    ))", "
    module ::RLispTestC24;def self.fib(globals)
      Proc.new do |*args|
        x, = *args
        t0 = globals[:<]
        t1 = t0.call(x, 2)
        if t1
          t2 = 1
        else
          t3 = globals[:+]
          t4 = globals[:fib]
          t5 = globals[:-]
          t6 = t5.call(x, 1)
          t7 = t4.call(t6)
          t8 = globals[:fib]
          t9 = globals[:-]
          t10 = t9.call(x, 2)
          t11 = t8.call(t10)
          t12 = t3.call(t7, t11)
          t2 = t12
        end
        t2
      end
    end;end
    t13 = ::RLispTestC24::fib(globals)
    globals[:fib] = t13
    t13
    ", 24)
  end

  def test_defun
    assert_compiles("(letmacro defun (fn (name args . code)
      `(let ,name (fn ,args ,@code))
    ))", "
    module ::RLispTestC25;def self.defun(globals)
      Proc.new do |*args|
        name, args, *code = *args
        t0 = [:fn, args, *code]
        t1 = [:let, name, t0]
        t1
      end
    end;end
    t2 = ::RLispTestC25::defun(globals)
    @macros[:defun] = t2
    t2
    ", 25)
  end
  
  def test_nested_scoping
    assert_compiles("(fn (tmp) (fn () `(do ,tmp)))",
    "
    module ::RLispTestC26;def self.anon_fn_1(globals, tmp)
      Proc.new do
        t0 = [:do, tmp]
        t0
      end
    end;end
    module ::RLispTestC26;def self.anon_fn(globals)
      Proc.new do |*args|
        tmp, = *args
        t1 = ::RLispTestC26::anon_fn_1(globals, tmp)
        t1
      end
    end;end
    t2 = ::RLispTestC26::anon_fn(globals)
    t2
    ", 26)
  end

  def test_self
    assert_compiles("self",
    "
    self
    ", 27)
  end
  
  def test_constants
    assert_compiles("Object",
    "
    ::Object
    ", 28)
    assert_compiles("Minitest::Test",
    "
    ::Minitest::Test
    ", 29)
  end

  def test_dot
    assert_compiles("(a . b)",
    "
    t0 = globals[:a]
    t1 = globals[:b]
    t2 = t0.call(*t1)
    t2
    ", 30)
    assert_compiles("(a b . c)",
    "
    t0 = globals[:a]
    t1 = globals[:b]
    t2 = globals[:c]
    t3 = t0.call(t1, *t2)
    t3
    ", 31)
    # The last one included just for completeness.
    # ( . c ) could reasonably mean either [:c] or [:".", :"c"].
    assert_compiles("(. c)",
    '
    t0 = globals[:"."]
    t1 = globals[:c]
    t2 = t0.call(t1)
    t2
    ', 32)
  end
end
