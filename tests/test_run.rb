#!/usr/bin/env ruby

require "minitest/autorun"
require 'rlisp'

class Test_RLisp_Run < Minitest::Test
  def bin_rlisp
    "./src/rlisp.rb"
  end

  def assert_runs(program, expected_output)
    actual_output = `#{bin_rlisp} tests/#{program}.rl`
    expected_output = expected_output.gsub(/^ {4}/, "").sub(/^\n/,"")
    assert_equal(expected_output, actual_output)
  end

  def assert_runs_program(program, expected_output)
    actual_output = `#{program}`
    expected_output = expected_output.gsub(/^ {4}/, "").sub(/^\n/,"")
    assert_equal(expected_output, actual_output)
  end

  # Make sure repl uses #inspect_lisp, not #to_s_lisp
  def test_repl
    assert_runs_program("#{bin_rlisp} -i <tests/repl-test.rl", '
    1
    "foo"
    (() "bar")
    ')
  end

  # Line numbers are going to be broken, but getting at least
  # filenames right is already helpful
  #
  # This varies wildly with ruby version. 3.2.2 test is here:
  def test_backtrace
    actual_output = `#{bin_rlisp} tests/backtrace.rl 2>&1`

    entries = actual_output.split(/\n/).reject{|e| e =~ /rlisp\.rb|rlisp_grammar\.rb|\d+ levels|default_globals/}

    assert_equal(6, entries.size, "There should be 6 relevant entries in backtrace")
    assert_match(/\tfrom tests\/backtrace\.rl:\d+/, entries[0])
    assert_match(/\tfrom tests\/backtrace\.rl:\d+/, entries[1])
    assert_match(/\tfrom \.\/src\/stdlib\.rl:\d+/, entries[2])
    assert_match(/\tfrom \.\/src\/stdlib\.rl:\d+/, entries[3])
    assert_match(/\tfrom tests\/backtrace\.rl:\d+/, entries[4])
    assert_match(/\tfrom tests\/backtrace\.rl:\d+/, entries[5])
  end

  def test_shebang_1_external
    # Run without options
    assert_runs_program("#{bin_rlisp} tests/shebang_test_1.rl", "
    ()
    ")

    assert_runs_program("#{bin_rlisp} tests/shebang_test_1.rl foo bar", "
    (foo bar)
    ")

    # -i should not be passed to the program
    assert_runs_program("#{bin_rlisp} -i tests/shebang_test_1.rl foo bar", "
    (foo bar)
    nil
    3
    ")

    assert_runs_program("#{bin_rlisp} tests/shebang_test_1.rl -i foo bar", "
    (-i foo bar)
    ")

    # -- support (or actually lack thereof)
    assert_runs_program("#{bin_rlisp} -i tests/shebang_test_1.rl -- foo bar", "
    (-- foo bar)
    nil
    3
    ")

    assert_runs_program("#{bin_rlisp} tests/shebang_test_1.rl -- -i foo bar", "
    (-- -i foo bar)
    ")

    assert_runs_program("#{bin_rlisp} tests/shebang_test_1.rl -i -- foo bar", "
    (-i -- foo bar)
    ")

    assert_runs_program("#{bin_rlisp} tests/shebang_test_1.rl -i foo -- bar", "
    (-i foo -- bar)
    ")
  end

  def test_shebang_1
    assert_runs_program("./tests/shebang_test_1.rl", "
    ()
    ")

    assert_runs_program("./tests/shebang_test_1.rl foo bar", "
    (foo bar)
    ")

    # -i -- etc. should be interpretted by the program, not by RLisp
    assert_runs_program("./tests/shebang_test_1.rl -i foo bar", "
    (-i foo bar)
    ")

    assert_runs_program("./tests/shebang_test_1.rl -- foo bar", "
    (-- foo bar)
    ")

    assert_runs_program("./tests/shebang_test_1.rl -- -i foo bar", "
    (-- -i foo bar)
    ")

    assert_runs_program("./tests/shebang_test_1.rl -i -- foo bar", "
    (-i -- foo bar)
    ")

    assert_runs_program("./tests/shebang_test_1.rl -i foo -- bar", "
    (-i foo -- bar)
    ")
  end

  # For now ignore #! options wher run externally:
  #   assert_runs_program("#{bin_rlisp} ./tests/shebang_test_2.rl foo bar", "
  #   (foo bar)
  #   ")
  # but in the future maybe:
  #   assert_runs_program("#{bin_rlisp} ./tests/shebang_test_2.rl foo bar", "
  #   (foo bar)
  #   nil
  #   3
  #   ")
  def test_shebang_2
    assert_runs_program("./tests/shebang_test_2.rl", "
    ()
    nil
    3
    ")

    assert_runs_program("./tests/shebang_test_2.rl foo bar", "
    (foo bar)
    nil
    3
    ")

    # -i -- etc. should be interpretted by the program, not by RLisp
    assert_runs_program("./tests/shebang_test_2.rl -i foo bar", "
    (-i foo bar)
    nil
    3
    ")

    assert_runs_program("./tests/shebang_test_2.rl -- foo bar", "
    (-- foo bar)
    nil
    3
    ")

    assert_runs_program("./tests/shebang_test_2.rl -- -i foo bar", "
    (-- -i foo bar)
    nil
    3
    ")

    assert_runs_program("./tests/shebang_test_2.rl -i -- foo bar", "
    (-i -- foo bar)
    nil
    3
    ")

    assert_runs_program("./tests/shebang_test_2.rl -i foo -- bar", "
    (-i foo -- bar)
    nil
    3
    ")
  end

  def test_one_liners
    assert_runs_program(%Q[#{bin_rlisp} -e '(print "Hello, world!")'], "
    Hello, world!
    ")
  end

  def test_adder
    assert_runs("adder", "
    6
    12
    ")
  end

  def test_array
    assert_runs("array", "
    1
    (5 6)
    (7 8 9)
    (2)
    ")
  end

  def test_case
    assert_runs("case", "
    two
    TWO
    ")
  end
  def test_class
    assert_runs("class", "
    <2,5>
    ")
  end
  def test_counter
    assert_runs("counter", "
    10
    11
    100
    12
    110
    ")
  end

  def test_fib
    assert_runs("fib", "
    (1 2 3 5 8)
    ")
  end

  def test_fib2
    assert_runs("fib2", "
    8
    ")
  end

  def test_hash
    # Can be either {:a=>6, :b=>4} or {:b=>4, :a=>6}
    actual_output = `#{bin_rlisp} tests/hash.rl`.sub("{:b=>4, :a=>6}", "{:a=>6, :b=>4}")
    expected_output = "10\n{:a=>6, :b=>4}\n"
    assert_equal(expected_output, actual_output)
  end

  def test_iter
    assert_runs("iter", "
    1
    2
    3
    ")
  end

  def test_lazy
    assert_runs("lazy", "
    Hello
    4
    Computing...
    result
    result
    ")
  end

  def test_let_export
    assert_runs("let-export", "
    4
    ")
  end

  def test_listops
    assert_runs("listops", "
    4950
    4950
    ")
  end

  def test_local_let
    assert_runs("local-let", "
    3
    2
    ")
  end

  def test_macro_and
    assert_runs("macro_and", "
    false
    false
    15
    ")
  end

  def test_macro_if
    assert_runs("macro_if", "
    Hello
    ")
  end

  def test_sign
    assert_runs("sign", "
    1
    0
    -1
    ")
  end

  def test_veclen
    assert_runs("veclen", "
    5.0
    ")
  end
end
