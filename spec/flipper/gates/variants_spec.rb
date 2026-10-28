RSpec.describe Flipper::Gates::Variants do
  subject { described_class.new }

  def context(variants, actors, feature_name: :search)
    Flipper::FeatureCheckContext.new(
      feature_name: feature_name,
      values: Flipper::GateValues.new(variants: variants),
      actors: actors&.map { |actor| Flipper::Types::Actor.wrap(actor) }
    )
  end

  def actors(count)
    Array.new(count) { |i| Flipper::Actor.new("User;#{i}") }
  end

  describe '#enabled?' do
    it 'is never enabled so variants do not count as enabling the feature' do
      expect(subject.enabled?({"control" => 100})).to be(false)
    end
  end

  describe '#open?' do
    it 'never opens' do
      expect(subject.open?(context({"control" => 100}, actors(1)))).to be(false)
    end
  end

  describe '#variant_for' do
    it 'returns nil without variants' do
      expect(subject.variant_for(context(nil, actors(1)))).to be_nil
    end

    it 'returns nil without actors' do
      expect(subject.variant_for(context({"control" => 100}, nil))).to be_nil
    end

    it 'does not depend on the order variants are stored in' do
      forward = {"blue" => 25, "control" => 50, "green" => 25}
      backward = {"green" => 25, "control" => 50, "blue" => 25}

      actors(100).each do |actor|
        expect(subject.variant_for(context(forward, [actor])))
          .to eq(subject.variant_for(context(backward, [actor])))
      end
    end

    it 'distributes actors by weight' do
      variants = {"control" => 50, "blue" => 30, "green" => 20}
      counts = Hash.new(0)
      actors(10_000).each { |actor| counts[subject.variant_for(context(variants, [actor]))] += 1 }

      expect(counts["control"]).to be_within(200).of(5_000)
      expect(counts["blue"]).to be_within(200).of(3_000)
      expect(counts["green"]).to be_within(200).of(2_000)
    end

    it 'never assigns a zero percent variant' do
      variants = {"control" => 100, "blue" => 0}
      results = actors(1_000).map { |actor| subject.variant_for(context(variants, [actor])) }
      expect(results.uniq).to eq(["control"])
    end

    it 'handles decimal weights' do
      variants = {"a" => 33.333, "b" => 33.333, "c" => 33.334}
      results = actors(3_000).map { |actor| subject.variant_for(context(variants, [actor])) }
      expect(results.uniq.sort).to eq(%w[a b c])
    end

    it 'buckets multiple actors the same regardless of order' do
      variants = {"control" => 50, "blue" => 50}
      a, b = actors(2)
      expect(subject.variant_for(context(variants, [a, b])))
        .to eq(subject.variant_for(context(variants, [b, a])))
    end

    it 'buckets differently per feature' do
      variants = {"control" => 50, "blue" => 50}
      search = actors(200).map { |actor| subject.variant_for(context(variants, [actor])) }
      other = actors(200).map { |actor| subject.variant_for(context(variants, [actor], feature_name: :other)) }
      expect(search).not_to eq(other)
    end
  end

  describe '#protects?' do
    it 'returns true for variants' do
      expect(subject.protects?(Flipper::Types::Variants.new("control" => 100))).to be(true)
    end

    it 'returns false for hashes, which belong to the expression gate' do
      expect(subject.protects?({"control" => 100})).to be(false)
    end
  end
end
