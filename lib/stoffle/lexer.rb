module Stoffle
  class Lexer
    BREAK_LINE = "\n"
    COMMENT = '#'
    WHITESPACE = [' ', "\r", "\t"].freeze
    KEYWORD = %w[var nil fn].freeze

    attr_reader :source, :tokens

    def initialize(source)
      @source = source
      @tokens = []
      @line = 0
      @next_p = 0
      @lexeme_start_p = 0
    end

    def start_tokenization
      tokenize while source_uncompleted?

      tokens << Token.new(Token::EOF, '', nil, after_source_end_location)
    end

    private

    attr_accessor :line, :next_p, :lexeme_start_p

    def tokenize
      self.lexeme_start_p = next_p
      token = nil

      c = consume

      return if WHITESPACE.include?(c)
      return ignore_comment_line if c == COMMENT

      if c == BREAK_LINE

        if tokens.last&.type != BREAK_LINE
          # Only adds one break line
          tokens << token_from_one_char_lex(c)
        end
        self.line += 1
        return
      end

      token = case c
              when '=' then token_from_one_char_lex(c)
              when '{' then token_from_one_char_lex(c)
              when '}' then token_from_one_char_lex(c)
              when '(' then token_from_one_char_lex(c)
              when ')' then token_from_one_char_lex(c)
              when ':' then token_from_one_char_lex(c)
              when ',' then token_from_one_char_lex(c)
              when '.' then token_from_one_char_lex(c)
              when '-' then token_from_one_char_lex(c)
              when '+' then token_from_one_char_lex(c)
              when '/' then token_from_one_char_lex(c)
              when '*' then token_from_one_char_lex(c)
              else
                if digit?(c)
                  number
                elsif identifier?(c)
                  identifier
                end
              end

      if token
        tokens << token
      else
        raise("Unknown character #{c}")
      end
    end

    def token_from_one_char_lex(lexeme)
      Token.new(lexeme.to_sym, lexeme, nil, current_location)
    end

    def identifier?(c)
      digit?(c) || alpha?(c)
    end

    def alpha?(c)
      c >= 'a' && c <= 'z' ||
        c >= 'A' && c <= 'Z' ||
        c == '_'
    end

    def consume
      c = lookahead
      self.next_p += 1
      c
    end

    def consume_digits
      consume while digit?(lookahead)
    end

    def consume_identifier
      consume while identifier?(lookahead)
    end

    def lookahead(offset = 1)
      lookahead_p = (next_p - 1) + offset
      return "\0" if lookahead_p >= source.length

      source[lookahead_p]
    end

    def ignore_comment_line
      consume while lookahead != BREAK_LINE && source_uncompleted?
    end

    def identifier
      consume_identifier

      identifier = source[lexeme_start_p..(next_p - 1)]
      type =
        if KEYWORD.include?(identifier)
          identifier.to_sym
        else
          :identifier
        end

      Token.new(type, identifier, nil, current_location)
    end

    def number
      consume_digits

      # Look for a fractional part.
      if lookahead == '.' && digit?(lookahead(2))
        consume # consuming the '.' character.
        consume_digits
      end

      lexeme = source[lexeme_start_p..(next_p - 1)]
      Token.new(:number, lexeme, lexeme.to_f, current_location)
    end

    def digit?(c)
      c >= '0' && c <= '9'
    end

    def source_completed?
      next_p >= source.length # our pointer starts at 0, so the last char is length - 1.
    end

    def source_uncompleted?
      !source_completed?
    end

    def current_location
      Location.new(line, lexeme_start_p, next_p - lexeme_start_p)
    end

    def after_source_end_location
      Location.new(line, next_p, 1)
    end
  end
end
