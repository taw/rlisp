#!/usr/bin/env ruby

require "minitest/autorun"
require 'rlisp_highlighter'

class Test_Indent < Minitest::Test
  def assert_highlights(code_out,code_in)
    highlighted = RLispHighlighter.highlight_html(code_in)
    header = "<html><head><title>Highlighted RLisp example</title></head><body><pre>"
    footer = "</pre></body></html>\n"
    
    highlighted[0...header.size] = "" if highlighted[0...header.size] == header
    highlighted[-footer.size..-1] = "" if highlighted[-footer.size..-1] == footer
  
    assert_equal(code_out, highlighted)
  end
  
  def test_highlighting
    assert_highlights(<<OUT,<<IN)
<span style='color: blue;'>(</span><span style='font-weight: 800;'>let</span> a <span style='color: blue;'>(</span>+ <span style='color: blue;'>1</span> <span style='color: blue;'>2</span><span style='color: blue;'>)</span><span style='color: blue;'>)</span>
OUT
(let a (+ 1 2))
IN

    assert_highlights(<<'OUT',<<'IN')
<span style='color: #00A000;'>"foo #{</span><span style='color: blue;'>1</span><span style='color: #00A000;'>} #{</span><span style='color: blue;'>(</span>+ <span style='color: blue;'>1</span> <span style='color: blue;'>2</span><span style='color: blue;'>)</span><span style='color: #00A000;'>} bar"</span>
OUT
"foo #{1} #{(+ 1 2)} bar"
IN

    assert_highlights(<<OUT,<<IN)
<span style='color: blue;'>(</span>list <span style='font-weight: 800;'>true</span> <span style='font-weight: 800;'>false</span> <span style='font-weight: 800;'>nil</span><span style='color: blue;'>)</span>
OUT
(list true false nil)
IN

    assert_highlights(<<OUT,<<IN)
<span style='color: blue;'>(</span><span style='font-weight: 800;'>let</span> a
  <span style='color: blue;'>(</span>+
    <span style='color: blue;'>1</span>
    <span style='color: blue;'>2</span><span style='color: blue;'>)</span>
  <span style='color: blue;'>)</span>


<span style='color: blue;'>(</span>foo <span style='color: blue;'>1</span> <span style='color: blue;'>2</span><span style='color: blue;'>)</span>

OUT
(let a
  (+
    1
    2)
  )


(foo 1 2)

IN

    assert_highlights(<<OUT,<<IN)
<span style='color: blue;'>(</span><span style='font-weight: 800;'>defmacro</span> cmds <span style='color: blue;'>(</span>recv <span style='font-weight: 800;'>.</span> args<span style='color: blue;'>)</span>
  <span style='color: blue;'>(</span><span style='font-weight: 800;'>let</span> tmp <span style='color: blue;'>(</span>gensym<span style='color: blue;'>)</span><span style='color: blue;'>)</span>
  <span style='color: blue;'>(</span><span style='font-weight: 800;'>let</span> args-expanded <span style='color: blue;'>[</span>args map <span style='font-weight: 800;'>&</span><span style='color: blue;'>(</span><span style='font-weight: 800;'>fn</span> <span style='color: blue;'>(</span>a<span style='color: blue;'>)</span>
    <span style='background-color: #D0D0FF;color: blue;'>`</span><span style='background-color: #D0D0FF;color: blue;'>(</span><span style='background-color: #D0D0FF;'>cmd</span><span style='background-color: #D0D0FF;'> </span><span style='background-color: #D0FFD0;color: blue;'>,</span><span style='background-color: #D0FFD0;'>recv</span><span style='background-color: #D0D0FF;'> </span><span style='background-color: #D0FFD0;color: blue;'>,@</span><span style='background-color: #D0FFD0;'>a</span><span style='background-color: #D0D0FF;color: blue;'>)</span>
  <span style='color: blue;'>)</span><span style='color: blue;'>]</span><span style='color: blue;'>)</span>
  <span style='background-color: #D0D0FF;color: blue;'>`</span><span style='background-color: #D0D0FF;color: blue;'>(</span><span style='background-color: #D0D0FF;font-weight: 800;'>do</span><span style='background-color: #D0D0FF;'> </span><span style='background-color: #D0FFD0;color: blue;'>,@</span><span style='background-color: #D0FFD0;'>args-expanded</span><span style='background-color: #D0D0FF;color: blue;'>)</span>
<span style='color: blue;'>)</span>
OUT
(defmacro cmds (recv . args)
  (let tmp (gensym))
  (let args-expanded [args map &(fn (a)
    `(cmd ,recv ,@a)
  )])
  `(do ,@args-expanded)
)
IN

    assert_highlights(<<OUT,<<IN)
<span style='color: #40C040;'>;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
</span><span style='color: #40C040;'>; generate an unique symbol - useful for macros
</span><span style='color: blue;'>(</span><span style='font-weight: 800;'>defun</span> gensym <span style='color: blue;'>(</span><span style='color: blue;'>)</span>
  <span style='color: blue;'>(</span>ruby-eval <span style='color: #00A000;'>"$gensym||=0; $gensym+=1; ('#:G' + $gensym.to_s).to_sym"</span><span style='color: blue;'>)</span><span style='color: blue;'>)</span>
OUT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; generate an unique symbol - useful for macros
(defun gensym ()
  (ruby-eval "$gensym||=0; $gensym+=1; ('#:G' + $gensym.to_s).to_sym"))
IN
  end
end
