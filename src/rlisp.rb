#!/usr/bin/env ruby

$:.unshift File.dirname(__FILE__)

require 'rlisp_support'
require 'rlisp_grammar'
require 'stringio'
require 'optparse'
require 'readline'

RLISP_VERSION="0.1.20070617"
RLISP_PATH=if ENV["RLISP_PATH"] then ENV["RLISP_PATH"].split(/:/) else [File.dirname(__FILE__), "/usr/lib/rlisp", "/usr/local/lib/rlisp"] end

class Symbol
  # Is the symbol legal RLisp variable ?
  # Some that are not:
  # * Funny characters
  # * Reserved keyword self
  # * Ruby constants (anything starting with a capital letter)
  #
  # * # is not a legal RLisp identifier, it's used by gensym
  def rlisp_variable?
    return false if [:self, :true, :false, :nil].include?(self)
    str = to_s
    str =~ /\A[a-zA-Z0-9!$%&*+\-.\/:#<=>?@^_\~]+\Z/ and str !~ /\A[A-Z0-9$@]/
  end

  def const_symbol?
    to_s =~ /\A[A-Z]/
  end

  def ivar_symbol?
    to_s =~ /\A@[^@]/
  end

  def cvar_symbol?
    to_s =~ /\A@@/
  end

  def gvar_symbol?
    to_s =~ /\A$/
  end

  RLisp_Special_Forms = [
    :quote, :fn, :if,
    :quasiquote, :unquote, :"unquote-splicing",
    :let, :set!,
    :letmacro # TODO: replace defmacro with (letmacro name (fn args . body))
    # :send and :do behave like functions, even if they are special forms
  ]
  # It should be kept up-to-date, or bad thing will happen
  def special_form?
    RLisp_Special_Forms.include? self
  end

  # Not all RLisp identifiers are valid Ruby identifiers,
  # * self
  # * t\d+ (used for temporaries)
  # * a_* (used for argument temporaries)
  # * everything with -
  def mangle
    raise "#{self} is not an RLisp variable" unless rlisp_variable?
    var = to_s
    return :"_#{var}" if var =~ /\At\d+\Z/ or var =~ /\Aa_/
    return var.gsub(/[^A-Za-z0-9]/){|c| sprintf "_%02x_", c.ord}.to_sym
  end
end

class Array
  attr_accessor :debug_info
end

class Variable
  def get
    @value
  end
  def set(value)
    @value = value
  end
end

# ReadlineIO implements only enough IO to make ANTLR::CharStream happy
class ReadlineIO
  def initialize(prompt)
    @prompt = prompt
    @buf = ""
    @eof = false
    raise "ReadlineIO cannot be used unless STDIN is a tty" unless STDIN.tty?
  end
  def read(sz)
    return nil if @eof
    raise "Only read(1) is supported" unless sz == 1
    if @buf == ""
      line = Readline.readline(@prompt, true)
      unless line
        @eof = true
        return nil
      end
      @buf << line
      @buf << "\n"
    end
    rv = @buf[0,1]
    @buf = @buf[1..-1]
    rv
  end
end

class CodeGenerator
  attr_reader :locals
  def initialize(class_name)
    @class_name = class_name
    @code    = []
    @indent  = 0
    @frames  = []
    @locals  = {}
    @line    = 1
    @fun_counter = {}
  end
  def parent_locals
    raise "CodeGenerator#parent_lolacs called at toplevel" if @frames.empty?
    @frames[-1][-1]
  end
  def generate_code!
    raise "CodeGenerator#generate_code! called when @indent not zero" unless @indent == 0
    #res = @code.map{|x| x+"\n"}.join
    res = (@code.join + "\n").gsub(/;\n/,"\n")
    @line += 1
    @code = []
    res
  end
  def line=(line)
    return if line == @line
    if line < @line
      #STDERR.puts "Trying to decrease line number"
    else
      #STDERR.puts "Advancing line number from #{@line} to #{line}"
      (line - @line).times {
        @code << "\n"
      }
      @line = line
    end
  end
  def push_frame
    @frames.push [@code, @indent, @locals]
    @code   = []
    @indent = 0
    @locals = {}
  end
  def pop_frame
    code_prv, indent_prv, locals_prv = *@frames.pop
    @code   = @code + code_prv
    @indent = indent_prv
    @locals = locals_prv
  end
  def <<(c)
    #@code << ("  " * @indent + c)
    #STDERR.puts "Code: #{c.inspect}"
    @code << c << ";"
  end

  def function(debug_fname, closure_str, args, has_rest_arg, has_proc_arg, &blk)
    debug_fname = if debug_fname
      debug_fname.mangle
    else
      :anon_fn
    end
    debug_fname= if @fun_counter[debug_fname]
      @fun_counter[debug_fname] += 1
      "#{debug_fname}_#{@fun_counter[debug_fname]}"
    else
      @fun_counter[debug_fname] = 0
      "#{debug_fname}"
    end

    self << "module ::#{@class_name};def self.#{debug_fname}(#{closure_str})"
    @indent += 1
    proc_new(args, has_rest_arg, has_proc_arg, &blk)
    @indent -= 1
    self << "end;end"

    "::#{@class_name}::#{debug_fname}"
  end

  def proc_new(args, has_rest_arg, has_proc_arg)
    # FIXME: Use (*args, &blk) instead of trying to do: foo, &bar = *args
    raise "Sorry, Ruby 1.8 doesn't support &-arguments to Proc.new{...}" if has_proc_arg

    arg_str = (if args.empty? then "" else " |*args|" end)
    self << "Proc.new do#{arg_str}"

    @indent += 1

    args_str = args.map{|a,tp,cls| "#{tp}#{if cls == :local_arg then 'a_' else '' end}#{a.mangle}"}.join(', ')
    if has_rest_arg
      self << "#{args_str} = *args"
    elsif !args.empty?
      self << "#{args_str}, = *args"
    end
    yield
    @indent -= 1
    self << "end"
  end

  # Use only with code_else
  def code_if(cond)
    self << "if #{cond}"
    @indent += 1
    yield
    @indent -= 1
  end

  def code_else
    self << "else"
    @indent += 1
    yield
    @indent -= 1
    self << "end"
  end

end

class RLispCompiler
  def tmp
    t = "t#{@counter}"
    @counter += 1
    return t
  end

  ##########################################
  # Macros and precompilation
  ##########################################
  # Expand macros until done, non-recursively
  def macroexpand(expr)
    return expr unless expr.is_a?(Array) and expr != []
    return macroexpand(@macros[expr[0]].call(*expr[1..-1])) if @macros[expr[0]]
    return expr
  end

  # Expand macros once, non-recursively
  def macroexpand_1(expr)
    return expr unless expr.is_a?(Array) and expr != []
    return @macros[expr[0]].call(*expr[1..-1]) if @macros[expr[0]]
    return expr
  end

  # Expand macros
  def precompile(expr, suggested_name=nil, self_debug_info=nil)
    return expr unless expr.is_a?(Array) and expr != []
    self_debug_info = expr.debug_info || self_debug_info
    if @macros[expr[0]]
      res = @macros[expr[0]].call(*expr[1..-1])
      return res unless res.is_a? Array
      res.debug_info = self_debug_info if self_debug_info
      return precompile(res, suggested_name, self_debug_info)
    end
    res = case expr[0]
    when :fn
      [:fn, expr[1], *expr[2..-1].map{|e| precompile(e, suggested_name, self_debug_info)}]
    when :let, :set!, :letmacro
      raise "(#{expr[0]} ...) requires 2 arguments, got #{expr.size-1}" unless expr.size == 3
      name = expr[1]
      body = precompile(expr[2], name, self_debug_info)
      [expr[0], name, body]
    when :quote
      expr
    when :quasiquote
      raise "quasiquote requires 1 argument, got #{expr.size-1}" unless expr.size == 2
      [:quasiquote, precompile_quasiquote(expr[1], suggested_name, self_debug_info)]
    when :if
      # Naive preprocessing is ok for special form (if ...)
      expr.map{|e| precompile(e, suggested_name, self_debug_info)}
    else
      raise "No clue what to do with: #{expr.inspect_lisp}" if (expr[0].is_a?(Symbol) and expr[0].special_form?)
      expr.map{|e| precompile(e, suggested_name, self_debug_info)}
    end
    if suggested_name
      res.debug_info = self_debug_info + [suggested_name] if self_debug_info
    else
      res.debug_info = self_debug_info
    end
    res
  end

  def precompile_quasiquote(expr, suggested_name, self_debug_info)
    return expr unless expr.is_a?(Array) and expr != []

    case expr[0]
    when :unquote, :"unquote-splicing"
      raise "#{expr[0]} expects 1 argument" unless expr.size == 2
      [expr[0], precompile(expr[1], suggested_name, self_debug_info)]
    else
      expr.map{|e| precompile_quasiquote(e, suggested_name, self_debug_info)}
    end
  end

  ##########################################
  # Extracting variables used
  ##########################################
  # * defs - variables defined inside current function
  # * uses - variables used
  # * nest - variables used in nested scopes
  # * mods - variables modified after use
  #        (let/set! - modified, even if there's just one)
  def extract_variables_used_fn(expr)
    defs, uses, nest, mods = {}, {}, {}, {}
    n_args, rest_arg, proc_arg = parse_args(expr[1])

    n_args.each{|a| defs[a] = true}
    defs[rest_arg] = true if rest_arg
    defs[proc_arg] = true if proc_arg

    expr[2..-1].each{|e| extract_variables_used_expr(e, defs, uses, nest, mods)}

    return [defs.keys, uses.keys, nest.keys, mods.keys]
  end

  def extract_variables_used_expr(expr, defs, uses, nest, mods)
    if expr.is_a? Symbol
      uses[expr] = true if expr.rlisp_variable?
    elsif expr.is_a? Array
      case expr[0]
      when :fn
        xdefs, xuses, xnest, xmods = *extract_variables_used_fn(expr)

        # Variables defined within nested function
        # never escape outside.
        xuses -= xdefs
        xmods -= xdefs

        # xnest implies xuses, so we don't really need to keep track of it

        # Variable modified below is still modified
        xmods.each{|v| mods[v] = true}

        # Variable used below is used and nested-used
        xuses.each{|v| uses[v] = true; nest[v] = true}
      when :quasiquote
        expr[1..-1].each{|c| extract_variables_used_qq(c, defs, uses, nest, mods)}
      when :if, :do, :unquote, :"unquote-splicing"
        expr[1..-1].each{|c| extract_variables_used_expr(c, defs, uses, nest, mods)}
      when :letmacro
        raise "Left side of letmacro must be a symbol" unless expr[1].is_a? Symbol
        raise "self is not a variable - (set! self ...) is illegal" if expr[1] == :self
        extract_variables_used_expr(expr[2], defs, uses, nest, mods)
      when :let
        raise "Left side of let must be a symbol" unless expr[1].is_a? Symbol
        raise "self is not a variable - (let self ...) is illegal" if expr[1] == :self
        # Constants can be let, it's legal just not supported
        # ivar/gvar/cvar can be "let", it means the same thing as set!-ing them
        if expr[1].rlisp_variable?
          defs[expr[1]] = true
          mods[expr[1]] = true
        end
        extract_variables_used_expr(expr[2], defs, uses, nest, mods)
      when :set!
        raise "Left side of set! must be a symbol" unless expr[1].is_a? Symbol
        raise "self is not a variable - (set! self ...) is illegal" if expr[1] == :self
        # Constants can be set!, it's legal just not supported
        # ivar/gvar/cvar can be set!
        mods[expr[1]] = true if expr[1].rlisp_variable?
        extract_variables_used_expr(expr[2], defs, uses, nest, mods)
      when :quote
        # No defs/uses
      else
        raise "No clue what to do with: #{expr.inspect_lisp}" if (expr[0].is_a?(Symbol) and expr[0].special_form?)
        expr.each{|c| extract_variables_used_expr(c, defs, uses, nest, mods)}
      end
    else
      # Ignore everything else
    end
  end

  def extract_variables_used_qq(expr, defs, uses, nest, mods)
    return unless expr.is_a? Array
    return if expr == []

    if (expr[0] == :unquote or expr[0] == :"unquote-splicing")
      raise "#{expr[0]} expects 1 argument" unless expr.size == 2
      extract_variables_used_expr(expr[1], defs, uses, nest, mods)
    else
      expr[1..-1].each{|e| extract_variables_used_qq(e, defs, uses, nest, mods)}
    end
  end
  ##########################################
  # Main code
  ##########################################
  attr_reader :globals

  def locals
    @cg.locals
  end

  def default_globals
    Hash.new{|ht,k|
      raise "No such global variable: #{k}"
    }.merge({
      :hd   => lambda{|obj| obj.first},
      :tl   => lambda{|obj| obj[1..-1]},
      :cons => lambda{|a, b| [a, *b]},
      :==   => lambda{|a,b| a == b },
      :"!=" => lambda{|a,b| a != b },
      :print => lambda{|*objs| objs.each{|o| print o.to_s_lisp}; print "\n"},
      :"ruby-eval" => lambda{|expr| eval(expr)},
      :"macroexpand" => lambda{|expr| macroexpand(expr)},
      :"macroexpand-1" => lambda{|expr| macroexpand_1(expr)},
      :eval    => lambda{|expr| run(expr)},
      :raise     => lambda{|*args| raise(*args)},
      :system    => lambda{|*args| system(*args)},

      # It will get integrated with the real require some day
      :require   => lambda{|file_name| run_file(file_name); nil},

      # Reflectiom
      :globals   => lambda{ @globals.keys.sort },
      :macros    => lambda{ @macros.keys.sort },

      # They're not exactly identical, but it's the simplest thing
      # which could possibly work
      :"macroexpand-rec" => lambda{|expr| precompile(expr)},
      # These should  really be magical identifiers, just like
      # self or 5
      :true  => true,
      :false => false,
      :nil   => nil,
    })
  end

  def initialize
    # @counter used only by tmp to generate temporaries
    @counter = 0
    @cg = nil
    @macros = {}
    @globals = default_globals
  end

  ##########################################
  # Code generation, refactor
  ##########################################
  def get(var)
    return var.to_s if [:self, :nil, :true, :false].include?(var)
    unless var.rlisp_variable?
      if var.const_symbol?
        return "::#{var}"
      else
        return "#{var}"
      end
    end
    varx = var.mangle
    case locals[var]
    when :local
      t = tmp
      set_tmp t, "#{varx}.get"
    when :local_simple
      t = tmp
      set_tmp t, "#{varx}"
    when :local_const
      # No temporaries needed for constants
      t = varx
    when :closure
      t = tmp
      set_tmp t, "#{varx}.get"
    when :closure_simple
      t = "#{varx}"
    else
      t = tmp
      set_tmp t, "globals[#{var.inspect}]"
    end
    t
  end

  def set(var, val)
    raise "Cannot set #{var} - it is a special keyword" if [:self, :nil, :true, :false].include?(var)

    unless var.rlisp_variable?
      if var.const_symbol?
        stmt "::#{var} = #{val}"
      else
        stmt "#{var} = #{val}"
      end
      return
    end
    varx = var.mangle
    case locals[var]
    when :local
      stmt "#{varx}.set #{val}"
    when :local_simple
      stmt "#{varx} = #{val}"
    when :local_const
      raise "Local constant variable #{var} cannot be modified"
    when :closure
      stmt "#{varx}.set #{val}"
    when :closure_simple
      raise "Pass-by-value closure variable #{var} cannot be modified"
    else
      stmt "globals[#{var.inspect}] = #{val}"
    end
  end

  def set_tmp(t, val)
    stmt "#{t} = #{val}"
  end

  def set_macro(name, t)
    stmt "@macros[#{name.inspect}] = #{t}"
  end
  ##########################################
  # End of code generation
  ##########################################

  def compile(expr)
    return expr.inspect if [Numeric, String, NilClass, FalseClass, TrueClass, Regexp].any?{|c| expr.is_a? c}
    return get(expr) if expr.is_a? Symbol
    if expr == []
      t = tmp
      set_tmp t, expr.inspect
      return t
    end
    raise "Don't know what to do with #{expr.class}: #{expr}" unless expr.is_a? Array
    #STDERR.puts "Compile: #{expr.debug_info.inspect_lisp} | #{expr.inspect_lisp}"

    if expr.debug_info
      @cg.line = expr.debug_info[1]
    end

    case expr[0]
    when :if
      expr = expr + [nil] if expr.size == 3
      raise "(if ...) requires 2 or 3 arguments" unless expr.size == 4
      cond, vthen, velse = *expr[1..3]
      tcond = compile(cond)
      t = tmp
      @cg.code_if(tcond) {
        set_tmp t, compile(vthen)
      }
      @cg.code_else {
        set_tmp t, compile(velse)
      }
    when :fn
      fc = compile_fn(expr)
      t = tmp
      set_tmp t, fc
    when :letmacro
      raise "(#{expr[0]} ...) requires 2 arguments, got #{expr.size-1}" unless expr.size == 3
      raise "First argument to (#{expr[0]} ...) must be a Symbol" unless expr[1].is_a? Symbol
      name, body = expr[1], expr[2]
      t = compile(body)
      set_macro name, t
    when :let, :set!
      raise "(#{expr[0]} ...) requires 2 arguments, got #{expr.size-1}" unless expr.size == 3
      raise "First argument to (#{expr[0]} ...) must be a Symbol" unless expr[1].is_a? Symbol
      raise "self is not a variable - (#{expr[0]} self ...) is illegal" if expr[1] == :self
      t = compile(expr[2])
      set expr[1], t
    when :do
      t = expr[1..-1].map{|a| compile(a)}[-1]
    when :quote
      raise "(quote ...) requires 1 argument" unless expr.size == 2
      return expr[1].inspect unless expr[1].is_a? Array
      t = tmp
      set_tmp t, "#{expr[1].inspect}"
    when :quasiquote
      raise "quasiquote requires 1 argument" unless expr.size == 2
      t, splice = compile_quasiquote(expr[1])
      raise "unquote-splicing illegal outside quasiquoted list" if splice
    when :unquote
      raise "unquote is illegal outside quasiquote"
    when :"unquote-splicing"
      raise "unquote-splicing is illegal outside quasiquote"
    when :send
      expr = expr[1..-1]
      block_arg = nil
      rest_arg = nil
      if expr[-2] == :"&" and expr.size >=3
        block_arg = expr.pop
        expr.pop
      end
      if expr[-2] == :"." and expr.size >=3
        rest_arg = expr.pop
        expr.pop
      end

      ts = expr.map{|a| compile(a)}
      rest_arg = compile(rest_arg) if rest_arg
      block_arg = compile(block_arg) if block_arg
      ts << "*#{rest_arg}" if rest_arg
      ts << "&#{block_arg}" if block_arg
      t = tmp
      if ts[0] == "self"
        if ts[1] =~ /\A:([a-zA-Z_]+)\Z/
          set_tmp t, "#{$1}(#{ts[2..-1].join(', ')})"
        else
          set_tmp t, "send(#{ts[1..-1].join(', ')})"
        end
      else
        set_tmp t, "#{ts[0]}.send(#{ts[1..-1].join(', ')})"
      end
    else
      raise "No clue what to do with: #{expr.inspect_lisp}" if (expr[0].is_a?(Symbol) and expr[0].special_form?)

      block_arg = nil
      rest_arg = nil
      if expr[-2] == :"&" and expr.size >=3
        block_arg = expr.pop
        expr.pop
      end
      if expr[-2] == :"." and expr.size >=3
        rest_arg = expr.pop
        expr.pop
      end

      ts = expr.map{|a| compile(a)}
      rest_arg = compile(rest_arg) if rest_arg
      block_arg = compile(block_arg) if block_arg
      ts << "*#{rest_arg}" if rest_arg
      ts << "&#{block_arg}" if block_arg
      t = tmp
      set_tmp t, "#{ts[0]}.call(#{ts[1..-1].join(', ')})"
    end
    t
  end

  def compile_quasiquote(expr)
    unless expr.is_a?(Array) and expr != []
      if expr.is_a? Array
        t = tmp
        set_tmp t, expr.inspect
        return [t, false]
      else
        return [expr.inspect, false]
      end
    end

    case expr[0]
    when :unquote, :"unquote-splicing"
      raise "#{expr[0]} expects 1 argument" unless expr.size == 2
      [compile(expr[1]), expr[0] == :"unquote-splicing"]
    else
      ts = expr.map{|a| compile_quasiquote(a) }
      t = tmp
      if ts[0..-2].any?{|v,splice| splice}
        # Splicing other than of last list member
        # In Ruby 1.8 * operator works only for the last element
        set_tmp t, ts.map{|v,splice| if splice then "#{v}" else "[#{v}]" end}.join(' + ')
      else
        if ts[-1][1]
          set_tmp t, "[#{ts[0..-2].map{|v,splice| v}.join(', ')}, *#{ts[-1][0]}]"
        else
          set_tmp t, "[#{ts.map{|v,splice| v}.join(', ')}]"
        end
      end
      [t, false]
    end
  end

  def parse_args(args)
    if args.is_a? Symbol
      [[], args, nil]
    elsif args.is_a? Array
      args.each{|a| raise "All arguments must by Symbols" unless a.is_a? Symbol}
      rest_arg = nil
      proc_arg = nil
      args, proc_arg = args[0..-3], args[-1] if args[-2] == :"&"
      args, rest_arg = args[0..-3], args[-1] if args[-2] == :"."

      [args, rest_arg, proc_arg]
    else
      raise "args in (fn args ...) must be a Symbol or a list, not #{args.class}"
    end
  end

  def compute_var_info(expr)
    defs, uses, nest, mods = extract_variables_used_fn(expr)
    parent_locals = @cg.parent_locals.to_a

    nest_and_mod = nest & mods

    ref_local_vars  = defs & nest_and_mod
    nonref_local_vars = defs - ref_local_vars
    val_local_vars  = nonref_local_vars & mods
    cst_local_vars  = nonref_local_vars & mods - val_local_vars

    parent_ref_vars = parent_locals.select{|v,cl| cl==:local or cl == :closure}.map{|v,cl| v}
    parent_val_vars = parent_locals.select{|v,cl| cl==:local_const or cl==:local_simple or cl == :closure_simple}.map{|v,cl| v}

    closure_vars = uses - defs
    ref_closure_vars = closure_vars & parent_ref_vars
    val_closure_vars = closure_vars & parent_val_vars
    # Get rid of globals
    closure_vars = ref_closure_vars + val_closure_vars

    n_args, rest_arg, proc_arg = parse_args(expr[1])
    args = n_args.map{|a| [a, ""]}
    args << [rest_arg, "*"] if rest_arg
    args << [proc_arg, "&"] if proc_arg
    args = args.map{|a, tp| [a, tp,
      if nest_and_mod.include?(a)
        :local_arg
      elsif !mods.include?(a)
        :local_const
      else
        :local_simple
      end]
    }

    args_by_name = args.map{|a,*rest| a}

    ref_local_vars   -= args_by_name
    val_local_vars   -= args_by_name
    ref_closure_vars -= args_by_name
    val_closure_vars -= args_by_name

    local_vars =
      args.map{|a, tp, cls| [a, cls]} +
      ref_local_vars.map{|v|[v, :local]} +
      val_local_vars.map{|v|[v, :local_simple]} +
      ref_closure_vars.map{|v| [v, :closure] } +
      val_closure_vars.map{|v| [v, :closure_simple]}

    return [args, local_vars, closure_vars, !!rest_arg, !!proc_arg]
  end

  def compile_fn(expr)
    @cg.push_frame

    debug_fname = (expr.debug_info||[])[3]

    args, local_vars, closure_vars, has_rest_arg, has_proc_arg = compute_var_info(expr)

    closure_str = ["globals", *closure_vars.map{|a| a.mangle}].join(', ')
    fname = @cg.function(debug_fname, closure_str, args, has_rest_arg, has_proc_arg) {
      local_vars.each{|v,cls| local_var v, cls}
      ts = expr[2..-1].map{|a| compile(a)}
      stmt "#{ts[-1]}"
    }
    call_args = ["globals", *closure_vars.map{|a| a.mangle}].join(', ')
    res = "#{fname}(#{call_args})"

    @cg.pop_frame

    return res
  end

  def local_var(var, cls)
    if cls == :local_arg
      # :local_arg nad :local differ only in initialization
      # After that, the rest of compiler doesn't
      # need to know the difference
      locals[var] = :local
      stmt "#{var.mangle} = Variable.new"
      set var, "a_#{var.mangle}"
    elsif cls == :local
      locals[var] = cls
      stmt "#{var.mangle} = Variable.new"
    else
      locals[var] = cls
    end
  end

  def stmt(c)
    @cg << c
  end

  def with_code_generator(class_name)
     old_cg = @cg
     @cg = CodeGenerator.new(class_name)
     yield
     res = @cg.generate_code!
     @cg = old_cg
     res
  end

  ##########################################
  # Drivers
  ##########################################
  def run_file(file_path, recompile=false)
    # If the path is not absolute, and it doesn't exist in ./
    # then search in other locations
    if file_path !~ /\A\// and !File.exist?(file_path)
      RLISP_PATH.each{|path|
        if File.exist?(path + "/" + file_path)
          file_path = path + "/" + file_path
          break
        end
      }
    end

    compiled_file = "#{file_path}c"

    unless File.exist?(compiled_file) and File.mtime(compiled_file) >= File.mtime(file_path)
      recompile = true
    end

    if recompile
      parser = RLispGrammar.new(File.open(file_path), file_path)
      compiled_record = ""
      with_code_generator("RLispC#{rand(10000000)}") do
        parser.each_expr{|expr|
          expr = precompile(expr)
          v = compile(expr)
          # Top-level expressions in files
          # don't really need that
          #stmt "#{v}"
          compiled = @cg.generate_code!
          STDERR.print compiled if $rlisp_debug
          cur_line = 1 + compiled_record.scan(/\n/).size
          eval(compiled, binding, file_path, cur_line)
          compiled_record << compiled
        }
      end
      File.open(compiled_file, "w") {|fh_out|
        fh_out.print compiled_record
      }
    else
      expr = File.read(compiled_file)
      eval(expr, binding, file_path)
    end
  end

  def run(expr, file_name=nil)
    compiled = with_code_generator("RLispC#{rand(10000000)}") do
      expr = precompile(expr)
      v = compile(expr)
      stmt "#{v}"
    end
    STDERR.print compiled if $rlisp_debug
    if file_name
      eval(compiled, binding, file_name)
    else
      eval(compiled)
    end
  end

  def repl(fh, interactive, file_name)
    parser = RLispGrammar.new(fh, file_name)
    if interactive
      parser.each_expr{|expr|
        begin
          res = run(expr, file_name)
          puts res.inspect_lisp
        rescue Exception => e
          STDERR.puts e
          STDERR.puts e.backtrace
        end
      }
    else
      parser.each_expr{|expr| run(expr, file_name)}
    end
  end

  def rlvm_compile(expr, test_id)
    with_code_generator(test_id) do
      expr = precompile(expr)
      v = compile(expr)
      stmt "#{v}"
    end
  end
end

#######################################################################
# MAIN                                #
#######################################################################
$rlisp_debug = false
def main
  interactive = :maybe
  nostdlib  = false
  recompile   = false
  stdlib_file = "stdlib.rl"
  input_file  = nil
  oneliner  = nil
  fh = nil

  ARGV.options{|opts|
    opts.banner = "Usage: #{$0} [OPTIONS] program.rl -- [PROGRAM OPTIONS]"

    opts.on("-h", "--help", "show this message") {
      puts opts
      exit
    }
    opts.on("-v", "--version", "show version") {
      puts "RLisp version #{RLISP_VERSION}"
      exit
    }
    opts.on("-i", "--interactive", "interactive mode") {
      interactive = true
    }
    opts.on("-b", "--batch", "non-interactive mode") {
      interactive = false
    }
    opts.on("-r", "--recompile", "recompile libraries") {
      recompile = true
    }
    opts.on("-n", "--nostdlib", "do not include stdlib") {
      nostdlib = true
    }
    opts.on("-d", "--debug", "debug mode") {
      $rlisp_debug = true
    }
    opts.on("-e", "=command", "execute command") {|input_code|
      input_file = "-e"
      fh = StringIO.new(input_code)
    }
    #opts.parse!
    opts.order!
  }
  unless fh or input_file or ARGV.empty?
    input_file = ARGV.shift
  end

  rlisp_compiler = RLispCompiler.new

  rlisp_compiler.run_file(stdlib_file, recompile) unless nostdlib

  interactive = (STDIN.tty? && input_file.nil?) if interactive == :maybe

  if input_file and not fh
    fh = File.open(input_file)
  end

  if input_file
    rlisp_compiler.repl(fh, interactive, input_file||'STDIN')
  else
    if interactive and STDIN.tty?
      fh = ReadlineIO.new("rlisp> ")
    else
      fh = STDIN
    end
  end
  rlisp_compiler.repl(fh, interactive, input_file||'STDIN')
end

if $0 == __FILE__
  main
end

$rlisp_debug = true if ENV["RLISP_DEBUG"]
