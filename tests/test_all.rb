#!/usr/bin/env ruby

require 'test_parser'
require 'test_rlvm'
require 'test_rlisp'
require 'test_run'
require 'test_support'
require 'test_indent'
require 'test_highlighter'

rlisp = RLispCompiler.new
rlisp.run_file 'stdlib.rl'
rlisp.run_file 'test_macros.rl'
rlisp.run_file 'tests/unit_test_test.rl'
rlisp.run_file 'tests/test_rlunit.rl'
rlisp.run_file 'test_rlunit.rl'
rlisp.run_file 'test_sql.rl'
rlisp.run_file 'test_syntax.rl'
rlisp.run_file 'test_text.rl'
