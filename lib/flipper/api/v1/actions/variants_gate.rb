require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class VariantsGate < Api::Action
          include FeatureNameFromRoute

          route %r{\A/features/(?<feature_name>.*)/variants/?\Z}

          def post
            feature = flipper[feature_name]

            begin
              feature.enable_variants variants_param
              decorated_feature = Decorators::Feature.new(feature)
              json_response(decorated_feature.as_json, 200)
            rescue ArgumentError
              json_error_response(:variants_invalid)
            end
          end

          def delete
            feature = flipper[feature_name]
            feature.disable_variants

            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          private

          def variants_param
            body = request.env["parsed_request_body".freeze] || {}.freeze
            body["variants"] || {}.freeze
          end
        end
      end
    end
  end
end
