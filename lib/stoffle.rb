require "readline"
require 'pathname'
require 'active_support'
require 'active_support/core_ext/string/inflections'
require_relative 'stoffle/version'
require_relative 'stoffle/location'
require_relative 'stoffle/token'
require_relative 'stoffle/lexer'
require_relative 'stoffle/parser'
require_relative 'stoffle/error/syntax/unexpected_token'
require_relative 'stoffle/error/syntax/unrecognized_token'
require_relative 'stoffle/error/runtime/undefined_variable'
require_relative 'stoffle/ast/shared/expression_collection'
require_relative 'stoffle/ast/expression'
require_relative 'stoffle/ast/program'
require_relative 'stoffle/ast/number'
require_relative 'stoffle/ast/nil'
require_relative 'stoffle/ast/identifier'
require_relative 'stoffle/ast/var_binding'
require_relative 'stoffle/ast/function_definition'
require_relative 'stoffle/ast/function_call'
require_relative 'stoffle/ast/block'
require_relative 'stoffle/ast/unary_operator'
require_relative 'stoffle/ast/binary_operator'
require_relative 'stoffle/runtime/stack_frame'
require_relative 'stoffle/interpreter'


module Stoffle
  def self.run_prompt
    interpreter = Stoffle::Interpreter.new
    while buf = Readline.readline("> ", true)
      begin
        puts "=> #{run(buf, interpreter: interpreter)}"
      rescue => e
        puts e.backtrace
        puts e.message
      end
    end
  end

  def self.run_file(file)
    file_content = File.read file
    run(file_content)
  end

  def self.run(source, env: {}, interpreter: nil)
    lexer = Stoffle::Lexer.new(source)
    parser = Stoffle::Parser.new(lexer.start_tokenization)
    interpreter ||= Stoffle::Interpreter.new(env: env)
    parser.parse
    puts parser.errors

    interpreter.interpret(parser.ast)
  end
end
