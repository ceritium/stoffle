module Stoffle
  class Interpreter
    attr_reader :program, :output, :env, :call_stack, :unwind_call_stack

    def initialize
      @output = []
      @env = {}
      @call_stack = []
      @unwind_call_stack = -1
    end

    def interpret(ast)
      @program = ast

      interpret_nodes(program.expressions)
    end

    private

    attr_writer :unwind_call_stack

    def return_detected?(node)
      node.type == 'return'
    end

    def interpret_nodes(nodes)
      last_value = nil

      nodes.each do |node|
        last_value = interpret_node(node)

        if unwind_call_stack == call_stack.length
          # We are still inside a function that returned, so we keep on bubbling up from its structures (e.g., conditionals, loops etc).
          return last_value
        elsif unwind_call_stack > call_stack.length
          # We returned from the function, so we reset the "unwind indicator".
          self.unwind_call_stack = -1
        end
      end

      last_value
    end

    def interpret_node(node)
      interpreter_method = "interpret_#{node.type}"
      send(interpreter_method, node)
    end

    # TODO Is this implementation REALLY the most straightforward in Ruby (apart from using eval)?
    def interpret_unary_operator(unary_op)
      case unary_op.operator
      when :'-'
        -(interpret_node(unary_op.operand))
      else # :'!'
        !(interpret_node(unary_op.operand))
      end
    end

    def interpret_binary_operator(binary_op)
      interpret_node(binary_op.left).send(binary_op.operator, interpret_node(binary_op.right))
    end

    def interpret_number(number)
      number.value
    end
  end
end
