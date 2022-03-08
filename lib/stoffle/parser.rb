module Stoffle
  class Parser
    attr_accessor :tokens, :ast, :errors

    EXPRESSION_TOKENS = [
      Token::NUMBER, Token::IDENTIFIER, Token::VAR, Token::NULL, Token::FN
    ].freeze

    BINARY_OPERATORS = [
      Token::PLUS,
      Token::MINUS,
      Token::STAR,
      Token::SLASH,
    ].freeze

    LOWEST_PRECEDENCE = 0
    PREFIX_PRECEDENCE = 7
    OPERATOR_PRECEDENCE = {
      Token::PLUS => 5,
      Token::MINUS => 5,
      Token::STAR => 6,
      Token::SLASH => 6,
      Token::LPAREN => 8
    }.freeze

    def initialize(tokens)
      @tokens = tokens
      @ast = AST::Program.new
      @next_p = 0
      @errors = []
      @level = 0
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

    def advance
      self.next_p += 1 unless at_end?
      previous
    end

    def consume(type = nil)
      if type.nil? || check(*type)
        return advance
      end
      if type
        unexpected_token_error(type)
      end
    end

    def check(*types)
      return false if at_end?

      current.is?(*types)
    end

    def end_of_line?(token)
      token.is?(Token::BREAK_LINE) || at_end?
    end

    def at_end?
      current&.is?(Token::EOF)
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
      if current.is?(*EXPRESSION_TOKENS)
        "parse_#{current.type}".to_sym
      elsif current.is?(Token::LPAREN)
        :parse_grouped_expr
      elsif end_of_line?(current)
        :parse_terminator
      end
    end

    def determine_infix_function(token = current)
      if token.is?(*BINARY_OPERATORS)
        :parse_binary_operator
      end
    end

    def parse_fn
      consume(Token::FN)
      consume(Token::LPAREN)
      fn = AST::FunctionDefinition.new
      params = []
      if current.is?(Token::IDENTIFIER)
        params << AST::Identifier.new(consume(Token::IDENTIFIER).lexeme)
        while current.is?(Token::COMMA)
          consume(Token::COMMA)
          params << AST::Identifier.new(consume(Token::IDENTIFIER).lexeme)
        end
      end
      consume(Token::RPAREN)
      fn.params = params

      fn.body = parse_block
      fn
    end

    def parse_fn_call
      identifier = consume(Token::IDENTIFIER)
      params = parse_function_call_args
      AST::FunctionCall.new(identifier.lexeme, params)
    end

    def parse_function_call_args
      args = []

      # Function call without arguments.
      if nxt.is?(Token::RPAREN)
        consume(Token::RPAREN)
        return args
      end

      consume
      args << parse_expr_recursively

      while nxt.is?(Token::COMMA)
        consume
        consume(Token::COMMA)
        args << parse_expr_recursively
      end

      return unless consume_if_nxt_is(build_token(:')', ')'))
      args
    end

    def parse_block
      consume(Token::LBRACE)
      block = AST::Block.new
      while !current.is?(Token::RBRACE)
        expr = parse_expr_recursively
        block << expr unless expr.nil?
        consume
      end
      unexpected_token_error(build_token(Token::EOF)) if current.is?(Token::EOF)
      consume(Token::RBRACE)

      block
    end

    def parse_var
      consume(Token::VAR)
      identifier = AST::Identifier.new(consume(Token::IDENTIFIER).lexeme)
      if end_of_line?(current)
        AST::VarBinding.new(identifier, AST::Nil.new)
      else
        consume(Token::EQUAL)
        AST::VarBinding.new(identifier, parse_expr_recursively)
      end
    end

    def parse_var_binding
      identifier = AST::Identifier.new(consume(Token::IDENTIFIER).lexeme)
      consume(Token::EQUAL)
      AST::VarBinding.new(identifier, parse_expr_recursively)
    end

    def parse_identifier
      if lookahead.is?(Token::EQUAL)
        parse_var_binding
      elsif lookahead.is?(Token::LPAREN)
        parse_fn_call
      else
        ident = AST::Identifier.new(current.lexeme)
        check_syntax_compliance(ident)
        ident
      end
    end

    def parse_nil
      AST::Nil.new
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

      # me...
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
      while !end_of_line?(current) && precedence < nxt_precedence
        infix_parsing_function = determine_infix_function(nxt)

        return expr if infix_parsing_function.nil?

        consume
        expr = send(infix_parsing_function, expr)
      end

      expr
    end
  end
end
