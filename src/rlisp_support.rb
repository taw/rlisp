# Lisp pretty-printing

# pretty_id support
#
# NOTE:
# Per-class pretty_id - it's not quite cool, because we sometimes
# want X and Y<X to have the same ids and sometimes don't,
# e.g. we definitely do not want all subclases of Object to share ids
# but we'd like subclasses of Opcode to do so.
# 
# In such case overload pretty_id_domain
class Object
  def pretty_id_domain
    @@pretty_id_domain ||= [{}, 0]
    @@pretty_id_domain
  end
  def pretty_id
    domain = pretty_id_domain
    unless domain[0][object_id]
      domain[0][object_id] = domain[1]
      domain[1] += 1
    end
    domain[0][object_id]
  end
end

class Object
  # Return string representation suitable for use in
  # (print obj)
  #
  # Example:
  # (print "Hello, world!")
  # Hello, world!
  def to_s_lisp
    to_s
  end
  # Return string representation suitable for use in
  # REPL printing
  #
  # Example:
  # repl> (let msg '("hello" "world"))
  # ("hello" "world")
  def inspect_lisp
    inspect
  end
end

# Make .. and ... methods
class Object
  define_method(:dotdot) {|other| self..other }
  define_method(:dotdotdot) {|other| self...other }
end

class Symbol
  include Comparable
  def <=>(other)
    to_s <=> other.to_s
  end
  protected :<=>
end

class Hash
  # Hash#to_s is rather useless
  alias_method :to_s_lisp, :inspect
end

class Symbol
  alias_method :inspect_lisp, :to_s
end

# [1, 2, 3] => (1 2 3)
class Array
  def to_s_lisp
    "(" + map{|x| x.to_s_lisp}.join(" ") + ")"
  end
  def inspect_lisp
    "(" + map{|x| x.inspect_lisp}.join(" ") + ")"
  end
end

# TrueClass/FalseClass - both work the same way
# or we could change to_s_lisp to display #t/#f ...

# We want "nil" not ""
class NilClass; alias_method :to_s_lisp, :inspect; end

class Function
  def to_s_lisp
    "#(fn:#{pretty_id} ...)"
  end
  alias_method :inspect_list, :to_s_lisp
end

# get/set are nicer than field-get/field-set
class Hash
  alias_method :get, :[]
  alias_method :set, :[]=
end
class Array
  alias_method :get, :[]
  alias_method :set, :[]=
end
class MatchData
  alias_method :get, :[]
end

class Symbol
  # FIXME: 1.8-specific, use $1.ord in 1.9
  def mangle_c
    to_s.gsub(/([^a-zA-Z0-9])/) { sprintf "_%02x", $1[0] }
  end
  def stringify_c
    '"' + to_s.gsub(/([\\"])/) { "\\#{$1}" } + '"'
  end
end
