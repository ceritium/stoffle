RSpec.describe Stoffle do
  it 'does have a version number' do
    expect(Stoffle::VERSION).not_to be nil
  end

  it "does some calculations" do
    expect(Stoffle.run("a = 22")).to eq(22)
    expect(Stoffle.run("a = 22
                       a * 2
                       ")).to eq(44)
    expect(Stoffle.run("+")).to eq(nil)
    expect(Stoffle.run("1")).to eq(1.0)
    expect(Stoffle.run("1+2")).to eq(3.0)
    expect(Stoffle.run("1+2*3")).to eq(7.0)
    expect(Stoffle.run("(1+2)*3")).to eq(9.0)
    expect(Stoffle.run("2.2 + (1+2)*3")).to eq(11.2)
    expect(Stoffle.run("
      # some comments
      (1+2)*3
      # foo
      22"
    )).to eq(22)
  end

  describe "Lexer" do
    it "parse assigment vars" do
      lexer = Stoffle::Lexer.new("a = 22")
      lexer.start_tokenization
      expect(lexer.tokens).to eq([
        Stoffle::Token.new(:identifier, "a", nil, Location.new(0, 0, 1)),
        Stoffle::Token.new(:"=", "=", nil, Location.new(0, 2, 1)),
        Stoffle::Token.new(:number, "22", 22.0, Location.new(0, 4, 2)),
        Stoffle::Token.new(:eof, "", nil, Location.new(0, 6, 1))
      ])
    end

    it "parse assigment" do
      lexer = Stoffle::Lexer.new("a = 22")
      lexer.start_tokenization
      expect(lexer.tokens).to eq([
        Stoffle::Token.new(:identifier, "a", nil, Location.new(0, 0, 1)),
        Stoffle::Token.new(:"=", "=", nil, Location.new(0, 2, 1)),
        Stoffle::Token.new(:number, "22", 22.0, Location.new(0, 4, 2)),
        Stoffle::Token.new(:eof, "", nil, Location.new(0, 6, 1))
      ])

    end
  end

  describe "Parser" do
    it "parse assignment and use of vars without errors" do
      lexer = Stoffle::Lexer.new("a = 22
                                 a * 2")
      parser = Stoffle::Parser.new(lexer.start_tokenization)
      parser.parse
      expect(parser.errors).to be_empty
    end
  end
end
