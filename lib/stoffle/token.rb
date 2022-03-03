require 'forwardable'

module Stoffle
  class Token

    AVAILABLE = [
      PLUS = :'+',
      MINUS = :'-',
      STAR = :'*',
      SLASH = :'/',

      EQUAL = :'=',
      BREAK_LINE = :"\n",
      EOF = :eof,

      NUMBER = :number,
      IDENTIFIER = :identifier,
      STRING = :string,
      VAR = :var,
      NULL = :nil,
      LPAREN = :'(',
      RPAREN = :')'
    ]

    extend Forwardable

    attr_reader :type, :lexeme, :literal, :location

    def_delegators :@location, :line, :col, :length

    def initialize(type, lexeme, literal, location)
      raise "Invalid type #{type}" unless AVAILABLE.include?(type)
      @type = type
      @lexeme = lexeme
      @literal = literal
      @location = location
    end

    def to_s
      "#{type} #{lexeme} #{literal}"
    end

    def ==(other)
      type == other.type &&
        lexeme == other.lexeme &&
        literal == other.literal &&
        location == other.location
    end

    def is?(*types)
      types.include?(type)
    end
  end
end
