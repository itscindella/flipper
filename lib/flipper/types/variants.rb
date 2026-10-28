require 'flipper/typecast'

module Flipper
  module Types
    class Variants < Type
      # Private: weights support up to 3 decimal places, matching the
      # percentage of actors gate.
      SCALING_FACTOR = 1_000
      private_constant :SCALING_FACTOR

      TOTAL = 100 * SCALING_FACTOR
      private_constant :TOTAL

      NUMERIC = /\A\s*-?\d+(\.\d+)?\s*\z/
      private_constant :NUMERIC

      # value - A Hash of String/Symbol variant name => percentage.
      def initialize(value)
        unless value.respond_to?(:each_pair)
          raise ArgumentError, "variants must be a Hash of name => percentage, but was #{value.inspect}"
        end

        @value = {}
        value.each_pair do |name, weight|
          # to_number turns non-numeric strings into 0, which would hide typos.
          if weight.is_a?(String) && weight !~ NUMERIC
            raise ArgumentError, "variant #{name.to_s.inspect} percentage must be a number, but was #{weight.inspect}"
          end

          @value[name.to_s.strip] = Typecast.to_number(weight)
        end
      end

      # Internal: Raises ArgumentError unless every variant has a name and the
      # percentages total exactly 100.
      #
      # Returns self.
      def validate!
        raise ArgumentError, "variants must include at least one variant" if @value.empty?

        total = @value.sum do |name, weight|
          raise ArgumentError, "variant names cannot be blank" if name.empty?

          if weight < 0 || weight > 100
            raise ArgumentError, "variant #{name.inspect} percentage must be between 0 and 100, but was #{weight}"
          end

          scaled = weight * SCALING_FACTOR
          # Tolerance absorbs float noise (33.333 * 1000 is 33332.999...).
          if (scaled - scaled.round).abs > 1e-6
            raise ArgumentError, "variant #{name.inspect} percentage can have at most 3 decimal places, but was #{weight}"
          end

          scaled.round
        end

        unless total == TOTAL
          raise ArgumentError, "variant percentages must total 100, but totaled #{total.to_f / SCALING_FACTOR}"
        end

        self
      end
    end
  end
end
