#!/usr/bin/ruby

require 'rlisp_grammar'

module RLispIndent
  def self.indent(code)
    tokens = RLispGrammarAlternative.tokenize(code)

    level = 0
    correction_list = []

    tokens.each_with_index{|(tok, cls), i|
      case cls
      when :open, :sqopen
        level += 1
      when :close, :sqclose
        level -= 1
      when :"whitespace-linestart"
        j, real_level = i+1, level
        while tokens[j] and (tokens[j][1] == :close or tokens[j][1] == :sqclose)
          j, real_level = j+1, real_level -1
        end
        correction_list << [i, real_level]
      end
    }
    
    domains = [(0...correction_list.size)]
    domain_level = 0
    while not domains.empty?
      domains_next_iter = []
      domains.each{|domain|
        domain_min_level = domain.map{|i| correction_list[i][1]}.min
        cur_new_domain = []
        domain.each{|i|
          if correction_list[i][1] == domain_min_level
            correction_list[i][1] = domain_level
            unless cur_new_domain.empty?
              domains_next_iter << cur_new_domain
              cur_new_domain = []
            end
          else
            cur_new_domain << i
          end
        }
        unless cur_new_domain.empty?
          domains_next_iter << cur_new_domain
        end
      }
      domain_level += 1
      domains = domains_next_iter
    end
    
    correction_list.each{|token_number, level|
      tokens[token_number][0] = "  " * level
    }
    
    code_out = tokens.map{|tok, cls| tok}.join
    return code_out
  end
end

if $0 == __FILE__
  print RLispIndent.indent(STDIN.read)
end
