RSpec.describe Stoffle do
  it 'does have a version number' do
    expect(Stoffle::VERSION).not_to be nil
  end

  it "does some calculations" do
    expect(Stoffle.run("+")).to eq(nil) # it should fail
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
end
