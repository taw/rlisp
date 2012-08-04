#!/usr/bin/ruby

require 'rlisp_grammar'

Highlighted_symbols = %w{
  do if let set! fn letmacro
  send quote quasiquote unquote unquote-splicing
  defun defmacro
  false true nil self
  cond and or hash match case
  & .
}

class RLispHighlighter
  # It does very minimal parsing, just grouping ( ... )
  def self.parse_code(code)
    res = []
    expr_stack = []
    next_q = []
    RLispGrammarAlternative.tokenize(code).map{|tok, cls|
      this_q, next_q = next_q, []
      res << [tok, cls]
      case cls
      when :quote, :quasiquote, :unquote, :"unquote-splicing"
        next_q = [["", :"end-quote-scope"], *this_q]
      when :open, :sqopen, :istr_beg
        expr_stack.push this_q
      # )/]/}..." cannot meaningfully follow `/'/,/,@
      # so we can ignore this_q
      # But we can as well include it for the sake of tag balance
      when :close, :sqclose, :istr_end
        res += this_q + expr_stack.pop
      when :float, :int, :rx, :string, :symbol, :istr_mid
        res += this_q
      when :whitespace, :"whitespace-nl", :"whitespace-linestart", :comment, :unknown, :shebang
        next_q = this_q
      else
        raise "Unknown token class #{cls}"
      end
    }
    res
  end

  def self.parse_code_q(code)
    q_stack = []
    parse_code(code).map {|tok, cls|
      case cls
      when :quote, :quasiquote, :unquote, :"unquote-splicing"
        q_stack.push cls
      when :"end-quote-scope"
        q_stack.pop
      end
      q_class = nil
      q_stack.each{|c|
        if c == :quote
          q_class = :quote
          break
        elsif (q_class == nil or q_class == :unquote) and c == :quasiquote
          q_class = :quasiquote
        elsif q_class == :quasiquote and (c == :unquote or c == :"unquote-splicing")
          q_class = :unquote
        end
      }
      [tok, cls, q_class]
    }.select{|tok, cls, q_class| cls != :"end-quote-scope"}
  end

  def self.highlight_html(code)
    res = ""
    res << "<html><head><title>Highlighted RLisp example</title></head><body><pre>"
    
    parse_code_q(code).each{|tok, cls, q_class|
      style = ""
      if q_class == :quote or q_class == :quasiquote
        style += "background-color: #D0D0FF;"
      elsif q_class == :unquote
        style += "background-color: #D0FFD0;"
      end

      case cls
      when :open, :sqopen, :close, :sqclose, :quote, :quasiquote, :"unquote-splicing", :unquote, :int, :float
        style += "color: blue;"
      when :string, :istr_beg, :istr_mid, :istr_end
        style += "color: #00A000;"
      when :shebang, :comment
        style += "color: #40C040;"
      when :rx
        style += "color: #FF8080;"
      when :symbol
        if Highlighted_symbols.include?(tok)
          style += "font-weight: 800;"
        end
      when :"whitespace-linestart", :"whitespace-nl"
        style = ""
      when :unknown, :whitespace
        # Do nothing
      else
        raise "Uknown token class: #{cls}"
      end
      res << if style == ""
        tok
      else
        "<span style='#{style}'>#{tok}</span>"
      end
    }
    res << "</pre></body></html>\n"
    res
  end

  # The colors are different than HTML because HTML is desplayed
  # on white or otherwise bright background, while terminals are normally black
  def self.highlight_ansi(code)
    res = ""
    
    parse_code_q(code).each{|tok, cls, q_class|
      style = []
      if q_class == :quote or q_class == :quasiquote
        style << '44'
      elsif q_class == :unquote
        style << '42'
      end

      case cls
      when :open, :sqopen, :close, :sqclose, :quote, :quasiquote, :"unquote-splicing", :unquote, :int, :float
        style << '34;1'
      when :string, :istr_beg, :istr_mid, :istr_end
        style << '32'
      when :shebang, :comment
        style << '32;1'
      when :rx
        style << '31;1'
      when :symbol
        if Highlighted_symbols.include?(tok)
          style << 1
        end
      when :"whitespace-linestart", :"whitespace-nl"
        style = []
      when :unknown, :whitespace
        # Do nothing
      else
        raise "Uknown token class: #{cls}"
      end
      res << if style.empty?
        tok
      else
        "\e[#{style.join(';')}m#{tok}\e[m"
      end
    }
    res
  end

  # No highlighting
  def self.highligtn_raw(code)
    res = ""
    RLispGrammarAlternative.tokenize(code).each{|tok, cls|
      res << tok
    }
    res
  end
end

if $0 == __FILE__
  if ARGV[0] == '--ansi' or ARGV[0] == '-a'
    print RLispHighlighter.highlight_ansi(STDIN.read)
  else
    print RLispHighlighter.highlight_html(STDIN.read)
  end
end
