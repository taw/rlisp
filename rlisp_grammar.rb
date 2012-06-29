class RLispGrammar
  def initialize(input, file_name="example.rl")
    if input.is_a? String
      @input = nil
      @buf = input.dup
      @eof = true
    else
      @input = input
      @buf = ""
      @eof = false
    end
    @tokens = []
    @file_name = file_name
    @line    = 1
    @column  = 0
  end
  def get_chars
    return if @eof
    c = @input.read(1)
    if c
      @buf << c
    else
      @eof = true
    end
  end
  def each_expr
    while true
      @tokens << get_token if @tokens.empty?
      return if @tokens[0][0] == :eof
      yield expr
    end
  end
  
  def expr
    if @tokens.empty?
       tok = get_token
    else
       tok = @tokens.shift
    end
    
    case tok[0]
    when :expr
      return tok[1]
    when :quote, :unquote, :quasiquote, :"unquote-splicing"
      res = [tok[0], expr]
      res.debug_info = [@file_name, tok[2], tok[3]]
      return res
    when :open
      res = []
      res.debug_info = [@file_name, tok[2], tok[3]]
      while true
         @tokens << get_token
         if @tokens[0][0] == :close
           @tokens.shift
           return res
         else
           res << expr
         end
      end
    when :sqopen
      res = [:send]
      res.debug_info = [@file_name, tok[2], tok[3]]
      while true
         @tokens << get_token
         if @tokens[0][0] == :sqclose
           @tokens.shift
           res[2] = [:quote, res[2]] unless res.size <= 2
           return res
         else
           res << expr
         end
      end
    when :istr_beg
      res = [:str, tok[1]]
      res.debug_info = [@file_name, tok[2], tok[3]]
      while true
         @tokens << get_token
         if @tokens[0][0] == :istr_end
           res << @tokens.shift[1]
           return res
         elsif @tokens[0][0] == :istr_mid
           res << @tokens.shift[1]
         else
           # We don't really know how many exprs will there be inside #{ ... }
           res << expr
         end
      end
    else
      raise "Expected expr, got #{tok[0]} at #{@file_name}:#{tok[2]}:#{tok[3]}"
    end
  end

  def eat(sz)
     eaten = @buf[0...sz]
     @buf = @buf[sz..-1]
     # eaten.each_char if we had it ...
     eaten.each_byte{|c|
     if c == ?\n
       @column = 0
       @line += 1
     else
       @column += 1
     end
     }
  end
  
  # Possible tokens:
  # * expr
  # * open, close
  # * istr_beg, istr_mid, istr_end
  # * sqopen, sqclose
  # * quote, quasiquote
  # * unquote, unquote-splicing
  # * eof
  def get_token
    column, line = @column, @line
    while true
      get_chars if @buf.empty? and not @eof
      return [:eof, nil, line, column] if @eof and @buf.empty?
      case @buf
      when /\A\(/
        eat(1)
        return [:open, nil, line, column]
      when /\A\)/
        eat(1)
        return [:close, nil, line, column]
      when /\A\[\]=/
        eat(3)
        return [:expr, :"[]=", line, column]
      when /\A\[\](.*)/m
        # Can be partial []=
        if ($1 == "") and not @eof
          get_chars
          redo
        end
        eat(2)
        return [:expr, :"[]", line, column]
      when /\A\[(.*)/m
        # Can be partial [] or []=
        if ($1 == "") and not @eof
          get_chars
          redo
        end
        eat(1)
        return [:sqopen, nil, line, column]
      when /\A\]/
        eat(1)
        return [:sqclose, nil, line, column]
      when /\A\'/
        eat(1)
        return [:quote, nil, line, column]
      when /\A\`/ # `
        eat(1)
        return [:quasiquote, nil, line, column]
      when /\A\,@/
        eat(2)
        return [:"unquote-splicing", nil, line, column]
      when /\A\,(.?)/m
        # Possible begin of ,@
        if $1 == "" and not @eof
          get_chars
          redo
        else
          eat(1)
          return [:unquote, nil, line, column]
        end
      when /\A([ \t\r\n]+)/
        eat($1.size)
        column, line = @column, @line
        redo
      when /\A(#!.*\n)/
        eat($1.size)
        column, line = @column, @line
        redo
      when /\A(;.*\n)/
        eat($1.size)
        column, line = @column, @line
        redo
      when /\A;/m
        # Partial COMMENT
        if @eof
          return
        else
          get_chars
          redo
        end
      when /\A#!/m
        # Partial SHEBANG
        if @eof
          return
        else
          get_chars
          redo
        end
      when /\A#t/
        eat(2)
        return [:expr, :true, line, column]
      when /\A#f/
        eat(2)
        return [:expr, :false, line, column]
      when /\A#\Z/m
        # Partial SHEBANG or #T or #F
        unless @eof
          get_chars
          redo
        end
      when /\A([+\-]?[0-9]+(?:(?:\.[0-9]+)?[eE][+\-]?[0-9]+|\.[0-9]+))(.?)/m
        # Possible FLOAT
        # Partial FLOAT also matches, so continue if possible
        s, c = $1, $2
        if (c == "" or c =~ /\A[eE]/)  and not @eof
          get_chars
          redo
        else
          eat(s.size)
          return [:expr, eval(s), line, column]
        end
      when /\A([+\-]?(?:[1-9][0-9]*|0x[0-9a-fA-F]+|0b[01]+|0o[0-7]+|0[0-7]+|0))(.?)/m
        # Possible INT
        # Partial INT also matches, so continue if possible
        # Partial FLOAT also matches, so handle it
        s, c = $1, $2
        if (c == "" or c =~ /\A[.eExbo]/) and not @eof
          get_chars
          redo
        else
          eat(s.size)
          return [:expr, eval(s), line, column]
        end
      when /\A([a-zA-Z!$%&*+\-.:<=>?@^_~][0-9a-zA-Z!$%&*+\-.:<=>?@^_~]*)(.?)/m
        # Possible ID
        # Partial ID also matches, so continue if possible
        if $2 == "" and not @eof
          get_chars
          redo
        else
          eat($1.size)
          s = $1.to_sym
          stt = Hash.new{|ht,k| k}.merge({ :".." => :dotdot, :"..." => :dotdotdot })
          return [:expr, stt[s], line, column]
        end
      when /\A("(?:[^"#\\]|#*\\.|#+[^{\\#"])*#*")/
        eat($1.size)
        return [:expr, eval($1), line, column]
      when /\A(("(?:[^"#\\]|#*\\.|#+[^{\\#"])*#*)#\{)/
        eat($1.size)
        return [:istr_beg, eval($2+'"'), line, column]
      when /\A(\}((?:[^"#\\]|#*\\.|#+[^{\\#"])*#*"))/
        eat($1.size)
        return [:istr_end, eval('"'+$2), line, column]
      when /\A(\}((?:[^"#\\]|#*\\.|#+[^{\\#"])*#*)#\{)/
        eat($1.size)
        return [:istr_mid, eval('"'+$2+'"'), line, column]
      when /\A"/ # "
        # Possible partial string/istr_beg
        if @eof
          raise "EOF inside string: #{@buf}"
        else
          get_chars
          redo
        end
      when /\A\}/ # "
        # Possible partial istr_mid/istr_end
        if @eof
          raise "EOF inside interpolated string: #{@buf}"
        else
          get_chars
          redo
        end
      when /\A(\/(?:[^\/\\]|\\.)*\/[mix]*)(.?)/
        if $2 == "" and not @eof
          get_chars
          redo
        else
          eat($1.size)
          return [:expr, eval($1), line, column]
        end
      when /\A\//
        # Possible partial regexp
        if @eof
          raise "EOF inside interpolated string: #{@buf}"
        else
          get_chars
          redo
        end
      else
        raise "Not sure what to do with: #{@buf}"
      end
    end    
  end
end

# Indent and highlighter do not use the normal lexer because
# * they must deal with invalid code (token class :unknown)
# * they do not ignore whitespace/whitespace-linestart/comment/shebang
#
# On the other hand the alternative parser eats all data at once,
# so it is simple, but not fit for iteractive (readline) use.
# The logic related to handling incomplete input in the main lexer
# is really ugly.
#
# Both lexers also have totally different APIs.
# Overall it's simpler to have two siple lexers than one complex lexer
# which would serve both functions + 2 API adapters.
module RLispGrammarAlternative
  # Token classes:
  # * close
  # * comment
  # * float
  # * int
  # * istr_beg
  # * istr_end
  # * istr_mid
  # * open
  # * quasiquote
  # * "unquote-splicing"
  # * quote
  # * rx
  # * shebang
  # * sqclose
  # * sqopen
  # * string
  # * symbol
  # * unknown
  # * unquote
  # * whitespace
  # * whitespace-nl
  # * whitespace-linestart
  def self.tokenize(buf)
    tokens = []
    nl_just_happened = true
    while not buf.empty?
      if nl_just_happened
        buf =~ /\A([ \t\r]*)/
        tokens << [$1, :"whitespace-linestart"]
        buf[0, $1.size] = ""
        nl_just_happened = false
        next
      end
      nl_will_happen = false
      sz, cls = case buf
      when /\A\(/
        [1, :open]
      when /\A\)/
        [1, :close]
      when /\A\[\]=/
        [3, :symbol]
      when /\A\[\]/
        [2, :symbol]
      when /\A\[/
        [1, :sqopen]
      when /\A\]/
        [1, :sqclose]
      when /\A\'/
        [1, :quote]
      when /\A\`/ # `
        [1, :quasiquote]
      when /\A\,@/
        [2, :"unquote-splicing"]
      when /\A\,/
        [1, :unquote]
      when /\A([ \t\r]+)/
        [$1.size, :whitespace]
      when /\A\n/
        nl_will_happen = true
        [1, :"whitespace-nl"]
      when /\A(#!.*\n)/
        nl_will_happen = true
        [$1.size, :shebang]
      when /\A(;.*\n)/
        nl_will_happen = true
        [$1.size, :comment]
      when /\A;/m
        [buf.size, :comment]
      when /\A#!/m
        [buf.size, :shebang]
      when /\A#t/
        [2, :symbol]
      when /\A#f/
        [2, :symbol]
      when /\A#\Z/m
        [1, :unknown]
      when /\A([+\-]?[0-9]+(?:(?:\.[0-9]+)?[eE][+\-]?[0-9]+|\.[0-9]+))/
        [$1.size, :float]
      when /\A([+\-]?(?:[1-9][0-9]*|0x[0-9a-fA-F]+|0b[01]+|0o[0-7]+|0[0-7]+|0))/
        [$1.size, :int]
      when /\A([a-zA-Z!$%&*+\-.:<=>?@^_~][0-9a-zA-Z!$%&*+\-.:<=>?@^_~]*)/
        [$1.size, :symbol]
      when /\A("(?:[^"#\\]|#*\\.|#+[^{\\#"])*#*")/
        [$1.size, :string]
      when /\A(("(?:[^"#\\]|#*\\.|#+[^{\\#"])*#*)#\{)/
        [$1.size, :istr_beg]
      when /\A(\}((?:[^"#\\]|#*\\.|#+[^{\\#"])*#*"))/
        [$1.size, :istr_end]
      when /\A(\}((?:[^"#\\]|#*\\.|#+[^{\\#"])*#*)#\{)/
        [$1.size, :istr_mid]
      when /\A"/ # "
        [buf.size, :unknown]
      when /\A\}/ # "
        [buf.size, :unknown]
      when /\A(\/(?:[^\/\\]|\\.)*\/[mix]*)(.?)/
        [$1.size, :rx]
      when /\A\//
        [1, :unknown]
      else
        [1, :unknown]
      end
      tokens << [buf[0, sz], cls]
      buf[0, sz] = ""
      nl_just_happened = nl_will_happen
    end
    return tokens
  end
end
