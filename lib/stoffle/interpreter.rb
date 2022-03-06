module Stoffle
  class Interpreter
    attr_reader :program, :output, :env, :call_stack, :unwind_call_stack

    def initialize(env: {})
      @output = []
      @env = env
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

    def interpret_nil(_node)
      nil
    end

    def interpret_var_binding(var_binding)
      env[var_binding.left.name] = interpret_node(var_binding.right)
    end

    def interpret_function_definition(fn)
      fn
    end

    def interpret_function_call(fn_call)
      fn_def = env[fn_call.name]
      stack_frame = Stoffle::Runtime::StackFrame.new(fn_def, fn_call)
      assign_function_args_to_params(stack_frame)
      # Executing the function body.
      call_stack << stack_frame
      value = interpret_nodes(fn_def.body.expressions)
      call_stack.pop
      value
    end

    def assign_function_args_to_params(stack_frame)
      fn_def = stack_frame.fn_def
      fn_call = stack_frame.fn_call

      given = fn_call.args.length
      expected = fn_def.params.length
      if given != expected
        raise Stoffle::Error::Runtime::WrongNumArg.new(fn_def.function_name_as_str, given, expected)
      end

      # Applying the values passed in this particular function call to the respective defined parameters.
      if fn_def.params != nil
        fn_def.params.each_with_index do |param, i|
          if env.has_key?(param.name)
            # A global variable is already defined. We assign the passed in value to it.
            env[param.name] = interpret_node(fn_call.args[i])
          else
            # A global variable with the same name doesn't exist. We create a new local variable.
            stack_frame.env[param.name] = interpret_node(fn_call.args[i])
          end
        end
      end
    end

    def interpret_identifier(identifier)
      if env.has_key?(identifier.name)
        # Global variable.
        env[identifier.name]
      elsif call_stack.length > 0 && call_stack.last.env.has_key?(identifier.name)
        # Local variable.
        call_stack.last.env[identifier.name]
      else
        # Undefined variable.
        raise Stoffle::Error::Runtime::UndefinedVariable.new(identifier.name)
      end
    end
  end
end
