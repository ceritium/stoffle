class Stoffle::AST::Nil < Stoffle::AST::Expression
  def initialize()
    super(nil)
  end

  def ==(other)
    value == other&.value
  end

  def children
    []
  end
end
