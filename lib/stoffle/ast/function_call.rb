class Stoffle::AST::FunctionCall < Stoffle::AST::Expression
  attr_accessor :name, :args

  def initialize(name, args = [])
    @name = name
    @args = args
  end

  def ==(other)
    children == other&.children
  end

  def children
    [name, args]
  end
end
