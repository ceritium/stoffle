module Stoffle
  module Type
    LIST = [
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
      NIL = :nil,
      OPEN_PARENTHESES = :'(',
    ]

    def self.[](types)
      list = Array(types)
      return types if LIST.intersection(list).count == list.count

      raise ArgumentError, "undefined type in #{types}"
    end
  end
end
