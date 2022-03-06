RSpec.describe Stoffle do
  it 'does have a version number' do
    expect(Stoffle::VERSION).not_to be nil
  end

  it 'accepts external env' do
    # expect(Stoffle.run('a()', env: { 'a' => -> () { 22 } })).to eq(22)
    expect(Stoffle.run('a', env: { 'a' => 22 })).to eq(22)
    expect(Stoffle.run('a * 2', env: { 'a' => 22 })).to eq(44)
  end

  it {
    r = Stoffle.run('
      var c = fn(a,b) { a + b }
      c(1,c(2,3))
                ')
    expect(r).to eq(6)
  }

  it { Stoffle.run('var c = fn(a,b) { a + b }
                   c'
                  ) }

  it 'does some calculations' do
    expect(Stoffle.run('var a')).to eq(nil)
    expect(Stoffle.run('var a = nil')).to eq(nil)
    expect(Stoffle.run('var a = 22')).to eq(22)
    expect(Stoffle.run('a = 22')).to eq(22)
    expect(Stoffle.run('a = nil')).to eq(nil)
    expect(Stoffle.run("a = 22
                       a * 2
                       ")).to eq(44)
    expect(Stoffle.run('+')).to eq(nil)
    expect(Stoffle.run('1')).to eq(1.0)
    expect(Stoffle.run('1+2')).to eq(3.0)
    expect(Stoffle.run('1+2*3')).to eq(7.0)
    expect(Stoffle.run('(1+2)*3')).to eq(9.0)
    expect(Stoffle.run('2.2 + (1+2)*3')).to eq(11.2)
    expect(Stoffle.run("
      # some comments
      (1+2)*3
      # foo
      22")).to eq(22)
  end

  describe 'Lexer' do
    it 'parses fn' do
      lexer = Stoffle::Lexer.new('fn(a,b) { a }')
      lexer.start_tokenization
      expect(lexer.tokens).to eq([
                                   Stoffle::Token.new(:fn, 'fn', nil, Location.new(0, 0, 2)),
                                   Stoffle::Token.new(:"(", '(', nil, Location.new(0, 2, 1)),
                                   Stoffle::Token.new(:identifier, 'a', nil, Location.new(0, 3, 1)),
                                   Stoffle::Token.new(:",", ',', nil, Location.new(0, 4, 1)),
                                   Stoffle::Token.new(:identifier, 'b', nil, Location.new(0, 5, 1)),
                                   Stoffle::Token.new(:")", ')', nil, Location.new(0, 6, 1)),
                                   Stoffle::Token.new(:"{", '{', nil, Location.new(0, 8, 1)),
                                   Stoffle::Token.new(:identifier, 'a', nil, Location.new(0, 10, 1)),
                                   Stoffle::Token.new(:"}", '}', nil, Location.new(0, 12, 1)),
                                   Stoffle::Token.new(:eof, '', nil, Location.new(0, 13, 1))
                                 ])

    end
    it 'parses nil' do
      lexer = Stoffle::Lexer.new('nil')
      lexer.start_tokenization
      expect(lexer.tokens).to eq([
                                   Stoffle::Token.new(:nil, 'nil', nil, Location.new(0, 0, 3)),
                                   Stoffle::Token.new(:eof, '', nil, Location.new(0, 3, 1))
                                 ])
    end

    it 'parses var' do
      lexer = Stoffle::Lexer.new('var a')
      lexer.start_tokenization
      expect(lexer.tokens).to eq([
                                   Stoffle::Token.new(:var, 'var', nil, Location.new(0, 0, 3)),
                                   Stoffle::Token.new(:identifier, 'a', nil, Location.new(0, 4, 1)),
                                   Stoffle::Token.new(:eof, '', nil, Location.new(0, 5, 1))
                                 ])
    end

    it 'parses assignment with nil' do
      lexer = Stoffle::Lexer.new('a = nil')
      lexer.start_tokenization
      expect(lexer.tokens).to eq([
                                   Stoffle::Token.new(:identifier, 'a', nil, Location.new(0, 0, 1)),
                                   Stoffle::Token.new(:"=", '=', nil, Location.new(0, 2, 1)),
                                   Stoffle::Token.new(:nil, 'nil', nil, Location.new(0, 4, 3)),
                                   Stoffle::Token.new(:eof, '', nil, Location.new(0, 7, 1))
                                 ])
    end

    it 'parse assigment vars' do
      lexer = Stoffle::Lexer.new('a = 22')
      lexer.start_tokenization
      expect(lexer.tokens).to eq([
                                   Stoffle::Token.new(:identifier, 'a', nil, Location.new(0, 0, 1)),
                                   Stoffle::Token.new(:"=", '=', nil, Location.new(0, 2, 1)),
                                   Stoffle::Token.new(:number, '22', 22.0, Location.new(0, 4, 2)),
                                   Stoffle::Token.new(:eof, '', nil, Location.new(0, 6, 1))
                                 ])
    end

    it 'parse with break line' do
      lexer = Stoffle::Lexer.new(<<~CODE
        a = 22
        b = 44
      CODE
                                )
      lexer.start_tokenization
      expect(lexer.tokens).to eq([
                                         Stoffle::Token.new(:identifier, 'a', nil, Location.new(0, 0, 1)),
                                         Stoffle::Token.new(:"=", '=', nil, Location.new(0, 2, 1)),
                                         Stoffle::Token.new(:number, '22', 22.0, Location.new(0, 4, 2)),
                                         Stoffle::Token.new(:"\n", "\n", nil, Location.new(0, 6, 1)),
                                         Stoffle::Token.new(:identifier, 'b', nil, Location.new(1, 7, 1)),
                                         Stoffle::Token.new(:"=", '=', nil, Location.new(1, 9, 1)),
                                         Stoffle::Token.new(:number, '44', 44.0, Location.new(1, 11, 2)),
                                         Stoffle::Token.new(:"\n", "\n", nil, Location.new(1, 13, 1)),
                                         Stoffle::Token.new(:eof, '', nil, Location.new(2, 14, 1))
                                       ])
    end

    it 'parse assigment' do
      lexer = Stoffle::Lexer.new('a = 22')
      lexer.start_tokenization
      expect(lexer.tokens).to eq([
                                   Stoffle::Token.new(:identifier, 'a', nil, Location.new(0, 0, 1)),
                                   Stoffle::Token.new(:"=", '=', nil, Location.new(0, 2, 1)),
                                   Stoffle::Token.new(:number, '22', 22.0, Location.new(0, 4, 2)),
                                   Stoffle::Token.new(:eof, '', nil, Location.new(0, 6, 1))
                                 ])
    end

    it 'tokenizes a fn call' do
      lexer = Stoffle::Lexer.new('a(22)')
      lexer.start_tokenization
      expect(lexer.tokens).to eq([
                                   Stoffle::Token.new(:identifier, 'a', nil,  Location.new(0, 0, 1)),
                                   Stoffle::Token.new(:"(", '(', nil,         Location.new(0, 1, 1)),
                                   Stoffle::Token.new(:number, '22', 22.0,    Location.new(0, 2, 2)),
                                   Stoffle::Token.new(:")", ')', nil,         Location.new(0, 4, 1)),
                                   Stoffle::Token.new(:eof, '', nil,          Location.new(0, 5, 1))
                                 ])
    end
  end

  describe 'Parser' do
    it 'parses a fn call' do
      lexer = Stoffle::Lexer.new('a(22, b)')
      parser = Stoffle::Parser.new(lexer.start_tokenization)
      parser.parse
      expect(parser.errors).to be_empty
    end
    it 'parses var without value' do
      lexer = Stoffle::Lexer.new("var a
                                 2 + 2")
      parser = Stoffle::Parser.new(lexer.start_tokenization)
      parser.parse
      expect(parser.errors).to be_empty
    end

    it 'parse assignment and use of vars without errors' do
      lexer = Stoffle::Lexer.new('a = nil')
      parser = Stoffle::Parser.new(lexer.start_tokenization)
      parser.parse
      expect(parser.errors).to be_empty
    end

    it 'parses fn' do
      lexer = Stoffle::Lexer.new('var d = fn(a,b) { c = a + b
c * 2}')
      parser = Stoffle::Parser.new(lexer.start_tokenization)
      parser.parse
      expect(parser.errors).to be_empty
    end
  end
end
