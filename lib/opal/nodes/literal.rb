require 'opal/nodes/base'

module Opal
  module Nodes
    class ValueNode < Base
      handle :true, :false, :self, :nil

      def compile
        # :self, :true, :false, :nil
        push type.to_s
      end
    end

    class LiteralNode < Base
      children :value
    end

    class NumericNode < LiteralNode
      handle :int, :float

      def compile
        push value.to_s
        wrap '(', ')' if recv?
      end
    end

    class StringNode < LiteralNode
      handle :str

      def compile
        push value.inspect
      end
    end

    class SymbolNode < LiteralNode
      handle :sym

      def compile
        push value.to_s.inspect
      end
    end

    class RegexpNode < LiteralNode
      handle :regexp

      def compile
        push((value == // ? /^/ : value).inspect)
      end
    end

    class XStringNode < LiteralNode
      handle :xstr

      def needs_semicolon?
        stmt? and !value.to_s.include?(';')
      end

      def compile
        push value.to_s
        push ';' if needs_semicolon?

        wrap '(', ')' if recv?
      end
    end

    class DynamicStringNode < Base
      handle :dstr

      def compile
        children.each_with_index do |part, idx|
          push " + " unless idx == 0

          if String === part
            push part.inspect
          elsif part.type == :evstr
            push "("
            push expr(part[1])
            push ")"
          elsif part.type == :str
            push part[1].inspect
          else
            raise "Bad dstr part"
          end

          wrap '(', ')' if recv?
        end
      end
    end

    class DynamicSymbolNode < Base
      handle :dsym

      def compile
        children.each_with_index do |part, idx|
          push " + " unless idx == 0

          if String === part
            push part.inspect
          elsif part.type == :evstr
            push expr(s(:call, part.last, :to_s, s(:arglist)))
          elsif part.type == :str
            push part.last.inspect
          else
            raise "Bad dsym part"
          end
        end

        wrap '(', ')'
      end
    end

    class DynamicXStringNode < Base
      handle :dxstr

      def requires_semicolon(code)
        stmt? and !code.include?(';')
      end

      def compile
        needs_semicolon = false

        children.each do |part|
          if String === part
            push part.to_s
            needs_semicolon = true if requires_semicolon(part.to_s)
          elsif part.type == :evstr
            push expr(part[1])
          elsif part.type == :str
            push part.last.to_s
            needs_semicolon = true if requires_semicolon(part.last.to_s)
          else
            raise "Bad dxstr part"
          end
        end

        push ';' if needs_semicolon
        wrap '(', ')' if recv?
      end
    end

    class DynamicRegexpNode < Base
      handle :dregx

      def compile
        children.each_with_index do |part, idx|
          push " + " unless idx == 0

          if String === part
            push part.inspect
          elsif part.type == :str
            push part[1].inspect
          else
            push expr(part[1])
          end
        end

        wrap '(new RegExp(', '))'
      end
    end

    class ExclusiveRangeNode < Base
      handle :dot2

      children :start, :finish

      def compile
        helper :range

        push "$range("
        push expr(start)
        push ", "
        push expr(finish)
        push ", false)"
      end
    end

    class InclusiveRangeNode < Base
      handle :dot3

      children :start, :finish

      def compile
        helper :range

        push "$range("
        push expr(start)
        push ", "
        push expr(finish)
        push ", true)"
      end
    end
  end
end