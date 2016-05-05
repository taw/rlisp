#!/usr/bin/env ruby

require "minitest/autorun"
require 'rlisp'

class Test_Tokenizer < Minitest::Test
  def test_tokenizer
    code = '2.3 4 , ,@ ` ( ) [ ] foo bar x-y u19 #t #f bah "foo" "bar #{ 3 }" "#{1}" [] []= "#{a} #{b} #{c}"'
    rg = RLispGrammar.new(code)
    assert_equal([:expr, 2.3, 1, 0], rg.get_token)
    assert_equal([:expr, 4, 1, 4], rg.get_token)
    assert_equal([:unquote, nil, 1, 6], rg.get_token)
    assert_equal([:"unquote-splicing", nil, 1, 8], rg.get_token)
    assert_equal([:quasiquote, nil, 1, 11], rg.get_token)
    assert_equal([:open, nil, 1, 13], rg.get_token)
    assert_equal([:close, nil, 1, 15], rg.get_token)
    assert_equal([:sqopen, nil, 1, 17], rg.get_token)
    assert_equal([:sqclose, nil, 1, 19], rg.get_token)
    assert_equal([:expr, :foo, 1, 21], rg.get_token)
    assert_equal([:expr, :bar, 1, 25], rg.get_token)
    assert_equal([:expr, :"x-y", 1, 29], rg.get_token)
    assert_equal([:expr, :u19, 1, 33], rg.get_token)
    assert_equal([:expr, :true, 1, 37], rg.get_token)
    assert_equal([:expr, :false, 1, 40], rg.get_token)
    assert_equal([:expr, :bah, 1, 43], rg.get_token)
    assert_equal([:expr, "foo", 1, 47], rg.get_token)
    assert_equal([:istr_beg, "bar ", 1, 53], rg.get_token)
    assert_equal([:expr, 3, 1, 61], rg.get_token)
    assert_equal([:istr_end, "", 1, 63], rg.get_token)
    assert_equal([:istr_beg, "", 1, 66], rg.get_token)
    assert_equal([:expr, 1, 1, 69], rg.get_token)
    assert_equal([:istr_end, "", 1, 70], rg.get_token)
    assert_equal([:expr, :"[]", 1, 73], rg.get_token)
    assert_equal([:expr, :"[]=", 1, 76], rg.get_token)
    assert_equal([:istr_beg, "", 1, 80], rg.get_token)
    assert_equal([:expr, :a, 1, 83], rg.get_token)
    assert_equal([:istr_mid, " ", 1, 84], rg.get_token)
    assert_equal([:expr, :b, 1, 88], rg.get_token)
    assert_equal([:istr_mid, " ", 1, 89], rg.get_token)
    assert_equal([:expr, :c, 1, 93], rg.get_token)
    assert_equal([:istr_end, "", 1, 94], rg.get_token)
    assert_equal([:eof, nil, 1, 96], rg.get_token)
  end
end
 