require 'zlib'

module Flipper
  module Gates
    class Variants < Gate
      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :variants
      end

      # Internal: Name converted to value safe for adapter.
      def key
        :variants
      end

      def data_type
        :json
      end

      # Variants only pick a value for actors other gates enable, so they never
      # count toward a feature being enabled.
      def enabled?(value)
        false
      end

      # Private: matches the percentage of actors gate so weights support up to
      # 3 decimal places.
      SCALING_FACTOR = 1_000
      private_constant :SCALING_FACTOR

      # Internal: Picks the variant for the actors in the context.
      #
      # Returns the String variant name or nil if no variants or actors.
      def variant_for(context)
        variants = context.values.variants
        return if variants.nil? || variants.empty? || !context.actors?

        actors = context.actors
        ids = if actors.size == 1
          actors.first.value
        else
          actors.map(&:value).sort.join
        end
        # Salted so variant buckets are independent of percentage_of_actors
        # buckets, which hash "#{feature_name}#{id}".
        bucket = Zlib.crc32("#{context.feature_name}:variants:#{ids}") % (100 * SCALING_FACTOR)

        # Sorted so assignment doesn't depend on adapter key order.
        cumulative = 0
        variants.sort_by { |name, _| name.to_s }.each do |name, weight|
          cumulative += (Typecast.to_number(weight) * SCALING_FACTOR).round
          return name.to_s if bucket < cumulative
        end

        nil
      end

      def protects?(thing)
        thing.is_a?(Types::Variants)
      end
    end
  end
end
