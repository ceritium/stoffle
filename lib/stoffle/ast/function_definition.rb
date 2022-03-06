class Stoffle::AST::FunctionDefinition < Stoffle::AST::Expression
  # attr_accessor :name, :params, :body
  attr_accessor :params, :body

  def initialize(fn_params = [], fn_body = nil)
    # @name = fn_name
    @params = fn_params
    @body = fn_body
  end

  def ==(other)
    children == other&.children
  end

  def children
    # [name, params, body]
    [params, body]
  end
end
