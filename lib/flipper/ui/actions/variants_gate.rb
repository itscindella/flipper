require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class VariantsGate < UI::Action
        include FeatureNameFromRoute

        route %r{\A/features/(?<feature_name>.*)/variants/?\Z}

        def post
          render_read_only if read_only?

          feature = flipper[feature_name]
          @feature = Decorators::Feature.new(feature)

          if params['action'] == 'Clear'
            feature.disable_variants
          else
            begin
              feature.enable_variants variants_param
            rescue ArgumentError => exception
              error = "Invalid variants: #{exception.message}"
              redirect_to("/features/#{Flipper::UI::Util.escape @feature.key}?error=#{Flipper::UI::Util.escape error}")
            end
          end

          redirect_to "/features/#{Flipper::UI::Util.escape @feature.key}"
        end

        private

        # Builds a Hash from the parallel names[] and weights[] form rows,
        # skipping rows left blank.
        def variants_param
          names = Array(params['names'])
          weights = Array(params['weights'])

          names.each_with_index.each_with_object({}) do |(name, index), variants|
            name = name.to_s.strip
            weight = weights[index].to_s.strip
            next if name.empty? && weight.empty?

            raise ArgumentError, "variant names must be unique, but #{name.inspect} was repeated" if variants.key?(name)
            raise ArgumentError, "variant #{name.inspect} is missing a percentage" if weight.empty?

            variants[name] = weight
          end
        end
      end
    end
  end
end
