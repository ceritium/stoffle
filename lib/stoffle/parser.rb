module Stoffle
  class Parser
    attr_accessor :tokens, :ast, :errors

    BINARY_OPERATORS = [
      Type::PLUS,
      Type::MINUS,
      Type::STAR,
      Type::SLASH,
    ].freeze

    LOWEST_PRECEDENCE = 0
    PREFIX_PRECEDENCE = 7
    OPERATOR_PRECEDENCE = {
      '+':  5,
      '-':  5,
      '*':  6,
      '/':  6,
      '(':  8
    }.freeze

    def initialize(tokens)
      @tokens = tokens
      @ast = AST::Program.new
      @next_p = 0
      @errors = []
    end

    def parse
      while pending_tokens?
        consume

        node = parse_expr_recursively
        ast << node if node != nil
      end

      ast
    end

    private

    attr_accessor :next_p

    def build_token(type, lexeme = nil)
      Token.new(type, lexeme, nil, nil)
    end

    def pending_tokens?
      next_p < tokens.length
    end

    def nxt_not_terminator?
      !end_of_line?(nxt)
    end

    def end_of_line?(token)
      Type[[:"\n", :eof]].include?(token.type)
    end

    def advance
      self.next_p += 1 unless at_end?
      previous
    end

    def consume(type = nil)
      if type.nil? || check(*type)
        return advance
      end

      unexpected_token_error(type) if type
    end

    def check(*types)
      return false if at_end?

      Type[types].include?(nxt.type)
    end

    def at_end?
      current && current.type == Type[:eof]
    end

    def consume_if_nxt_is(expected)
      if nxt.type == expected.type
        consume
        true
      else
        unexpected_token_error(expected)
        false
      end
    end

    def previous
      lookahead(-1)
    end

    def current
      lookahead(0)
    end

    def nxt
      lookahead
    end

    def lookahead(offset = 1)
      lookahead_p = (next_p - 1) + offset
      return nil if lookahead_p < 0 || lookahead_p >= tokens.length

      tokens[lookahead_p]
    end

    def current_precedence
      OPERATOR_PRECEDENCE[current.type] || LOWEST_PRECEDENCE
    end

    def nxt_precedence
      OPERATOR_PRECEDENCE[nxt.type] || LOWEST_PRECEDENCE
    end

    def unrecognized_token_error
      errors << Error::Syntax::UnrecognizedToken.new(current)
    end

    def unexpected_token_error(expected = nil)
      errors << Error::Syntax::UnexpectedToken.new(current, nxt, expected)
    end

    def check_syntax_compliance(ast_node)
      return if ast_node.expects?(nxt)
      unexpected_token_error
    end

    def determine_parsing_function
      if Type[[:number, :identifier, :var, :nil]].include?(current.type)
        "parse_#{current.type}".to_sym
      elsif current.type == Type[:'(']
        :parse_grouped_expr
      elsif end_of_line?(current)
        :parse_terminator
      end
    end

    def determine_infix_function(token = current)
      if (BINARY_OPERATORS).include?(token.type)
        :parse_binary_operator
      end
    end

    def parse_var
      consume(:identifier)
      if end_of_line?(nxt)
        identifier = AST::Identifier.new(current.lexeme)
        AST::VarBinding.new(identifier, AST::Nil.new())
      end
    end

    def parse_var_binding
      identifier = AST::Identifier.new(current.lexeme)
      consume(:"=")
      consume([:number, :nil, :string, :identifier])
      AST::VarBinding.new(identifier, parse_expr_recursively)
    end

    def parse_identifier
      if lookahead.type == :"="
        parse_var_binding
      else
        ident = AST::Identifier.new(current.lexeme)
        check_syntax_compliance(ident)
        ident
      end
    end

    def parse_nil
      AST::Nil.new()
    end

    def check_syntax_compliance(ast_node)
      return if ast_node.expects?(nxt.type)

      unexpected_token_error
    end


    def parse_number
      AST::Number.new(current.literal)
    end

    def parse_grouped_expr
      consume

      expr = parse_expr_recursively
      return unless consume_if_nxt_is(build_token(:')', ')'))

      expr
    end

    # TODO Temporary impl; reflect more deeply about the appropriate way of parsing a terminator.
    def parse_terminator
      nil
    end

    def parse_binary_operator(left)
      op = AST::BinaryOperator.new(current.type, left)
      op_precedence = current_precedence

      consume
      op.right = parse_expr_recursively(op_precedence)

      op
    end

    def parse_expr_recursively(precedence = LOWEST_PRECEDENCE)
      parsing_function = determine_parsing_function
      if parsing_function.nil?
        unrecognized_token_error
        return
      end

      expr = send(parsing_function)
      return if expr.nil? # When expr is nil, it means we have reached a \n or a eof.

      # Note that here we are checking the NEXT token.
      while nxt_not_terminator? && precedence < nxt_precedence
        infix_parsing_function = determine_infix_function(nxt)

        return expr if infix_parsing_function.nil?

        consume
        expr = send(infix_parsing_function, expr)
      end

      expr
    end
  end
end
