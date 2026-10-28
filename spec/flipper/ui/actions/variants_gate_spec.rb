RSpec.describe Flipper::UI::Actions::VariantsGate do
  let(:token) do
    if Rack::Protection::AuthenticityToken.respond_to?(:random_token)
      Rack::Protection::AuthenticityToken.random_token
    else
      'a'
    end
  end
  let(:session) do
    { :csrf => token, 'csrf' => token, '_csrf_token' => token }
  end

  describe 'POST /features/:feature/variants' do
    context 'with valid variants' do
      before do
        post 'features/search/variants',
             { 'names' => ['control', 'blue', ''], 'weights' => ['50', '50', ''], 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'sets the variants, skipping blank rows' do
        expect(flipper[:search].variants_value).to eq("control" => 50, "blue" => 50)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/search')
      end
    end

    context 'with space in feature name' do
      before do
        post 'features/sp+ace/variants',
             { 'names' => ['control'], 'weights' => ['100'], 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'sets the variants' do
        expect(flipper["sp ace"].variants_value).to eq("control" => 100)
      end

      it 'redirects back to feature' do
        expect(last_response.headers['location']).to eq('/features/sp+ace')
      end
    end

    [
      ['percentages that do not total 100', ['control', 'blue'], ['50', '40'], /total 100/],
      ['duplicate names', ['control', 'control'], ['50', '50'], /unique/],
      ['a name without a percentage', ['control', 'blue'], ['100', ''], /missing a percentage/],
      ['a percentage without a name', ['control', ''], ['50', '50'], /blank/],
      ['only blank rows', ['', ''], ['', ''], /at least one/],
    ].each do |description, names, weights, message|
      context "with #{description}" do
        before do
          flipper[:search].enable_variants("control" => 100)
          post 'features/search/variants',
               { 'names' => names, 'weights' => weights, 'authenticity_token' => token },
               'rack.session' => session
        end

        it 'does not change the variants' do
          expect(flipper[:search].variants_value).to eq("control" => 100)
        end

        it 'redirects back to feature with an error' do
          expect(last_response.status).to be(302)
          location = last_response.headers['location']
          expect(location).to start_with('/features/search?error=')
          expect(Rack::Utils.unescape(location)).to match(message)
        end
      end
    end

    context 'with action Clear' do
      before do
        flipper[:search].enable_variants("control" => 100)
        post 'features/search/variants',
             { 'action' => 'Clear', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'removes the variants' do
        expect(flipper[:search].variants_value).to be_nil
      end

      it 'redirects back to feature' do
        expect(last_response.headers['location']).to eq('/features/search')
      end
    end
  end
end
