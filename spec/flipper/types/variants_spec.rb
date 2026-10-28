RSpec.describe Flipper::Types::Variants do
  describe '#initialize' do
    it 'normalizes names to stripped strings and weights to numbers' do
      variants = described_class.new(control: "50", " blue " => 25.5, "green" => 24.5)
      expect(variants.value).to eq("control" => 50, "blue" => 25.5, "green" => 24.5)
    end

    it 'raises for non hash values' do
      expect { described_class.new(nil) }.to raise_error(ArgumentError, /must be a Hash/)
      expect { described_class.new(["control", 100]) }.to raise_error(ArgumentError, /must be a Hash/)
    end

    it 'raises for non numeric string weights' do
      expect { described_class.new("control" => "fifty") }.to raise_error(ArgumentError, /must be a number/)
    end

    it 'raises for weights that cannot be numbers' do
      expect { described_class.new("control" => [1]) }.to raise_error(ArgumentError)
    end
  end

  describe '#validate!' do
    it 'returns self when percentages total 100' do
      variants = described_class.new("control" => 50, "blue" => 50)
      expect(variants.validate!).to be(variants)
    end

    it 'allows a single variant at 100' do
      expect { described_class.new("control" => 100).validate! }.not_to raise_error
    end

    it 'allows a zero percent variant' do
      expect { described_class.new("control" => 100, "blue" => 0).validate! }.not_to raise_error
    end

    it 'allows up to 3 decimal places without float drift' do
      variants = described_class.new("a" => 33.333, "b" => 33.333, "c" => 33.334)
      expect { variants.validate! }.not_to raise_error
      expect { described_class.new("a" => "0.1", "b" => "0.2", "c" => "99.7").validate! }.not_to raise_error
    end

    it 'raises for more than 3 decimal places' do
      variants = described_class.new("a" => 33.3333, "b" => 66.6667)
      expect { variants.validate! }.to raise_error(ArgumentError, /3 decimal places/)
    end

    it 'raises when empty' do
      expect { described_class.new({}).validate! }.to raise_error(ArgumentError, /at least one/)
    end

    it 'raises for blank names' do
      expect { described_class.new(" " => 100).validate! }.to raise_error(ArgumentError, /blank/)
    end

    it 'raises for percentages out of range' do
      expect { described_class.new("a" => -10, "b" => 110).validate! }.to raise_error(ArgumentError, /between 0 and 100/)
    end

    it 'raises when percentages do not total 100' do
      expect { described_class.new("a" => 50, "b" => 40).validate! }.to raise_error(ArgumentError, /total 100, but totaled 90.0/)
      expect { described_class.new("a" => 60, "b" => 50).validate! }.to raise_error(ArgumentError, /total 100/)
    end
  end
end
