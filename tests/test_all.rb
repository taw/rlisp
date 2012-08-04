#!/usr/bin/env ruby

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + "/../src"

require 'test_parser'
require 'test_rlvm'
require 'test_rlisp'
require 'test_run'
require 'test_support'
require 'test_indent'
require 'test_highlighter'
require 'test_tokenizer'

RLISP_PATH << File.dirname(__FILE__)
RLISP_PATH << File.dirname(__FILE__) + "/../src"

rlisp = RLispCompiler.new
rlisp.run_file 'stdlib.rl'
rlisp.run_file 'test_macros.rl'
rlisp.run_file 'unit_test_test.rl'
rlisp.run_file 'test_rlunit.rl'
rlisp.run_file 'test_rlunit_2.rl'
rlisp.run_file 'test_sql.rl'
rlisp.run_file 'test_syntax.rl'
rlisp.run_file 'test_text.rl'
