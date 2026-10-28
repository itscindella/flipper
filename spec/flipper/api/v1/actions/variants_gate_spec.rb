RSpec.describe Flipper::Api::V1::Actions::VariantsGate do
  let(:app) { build_api(flipper) }
  let(:split) { {"control" => 50, "blue" => 50} }
  let(:variants_invalid_response) do
    {
      'code' => 9,
      'message' => 'Variants must be named and their percentages must total 100.',
      'more_info' => api_error_code_reference_url,
    }
  end

  describe 'enable' do
    before do
      post '/features/my_feature/variants', JSON.dump(variants: split),
        "CONTENT_TYPE" => "application/json"
    end

    it 'sets variants for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].variants_value).to eq(split)
      expect(flipper[:my_feature].enabled_gate_names).to be_empty
    end

    it 'returns decorated feature with variants' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'variants' }
      expect(gate['value']).to eq(split)
    end
  end

  describe 'enable feature with slash in name' do
    before do
      post '/features/my/feature/variants', JSON.dump(variants: split),
        "CONTENT_TYPE" => "application/json"
    end

    it 'sets variants for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper["my/feature"].variants_value).to eq(split)
    end
  end

  describe 'disable' do
    before do
      flipper[:my_feature].enable_variants(split)
      delete '/features/my_feature/variants', JSON.dump({}),
        "CONTENT_TYPE" => "application/json"
    end

    it 'removes variants for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].variants_value).to be_nil
    end

    it 'returns decorated feature without variants' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'variants' }
      expect(gate['value']).to be_nil
    end
  end

  [
    ['percentages that do not total 100', {variants: {"control" => 50, "blue" => 40}}],
    ['no variants', {variants: {}}],
    ['missing variants key', {}],
    ['non hash variants', {variants: ["control"]}],
    ['non numeric percentage', {variants: {"control" => "all"}}],
  ].each do |description, body|
    describe "enable with #{description}" do
      before do
        post '/features/my_feature/variants', JSON.dump(body),
          "CONTENT_TYPE" => "application/json"
      end

      it 'returns correct error response and stores nothing' do
        expect(last_response.status).to eq(422)
        expect(json_response).to eq(variants_invalid_response)
        expect(flipper[:my_feature].variants_value).to be_nil
      end
    end
  end
end
