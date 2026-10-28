require 'set'
require 'flipper/typecast'

module Flipper
  class GateValues
    attr_reader :boolean
    attr_reader :actors
    attr_reader :groups
    attr_reader :expression
    attr_reader :percentage_of_actors
    attr_reader :percentage_of_time
    attr_reader :variants

    def initialize(adapter_values)
      @boolean = Typecast.to_boolean(adapter_values[:boolean])
      @actors = Typecast.to_set(adapter_values[:actors])
      @groups = Typecast.to_set(adapter_values[:groups])
      @expression = adapter_values[:expression]
      @percentage_of_actors = Typecast.to_number(adapter_values[:percentage_of_actors])
      @percentage_of_time = Typecast.to_number(adapter_values[:percentage_of_time])
      @variants = to_variants(adapter_values[:variants])
    end

    def eql?(other)
      self.class.eql?(other.class) &&
        boolean == other.boolean &&
        actors == other.actors &&
        groups == other.groups &&
        expression == other.expression &&
        percentage_of_actors == other.percentage_of_actors &&
        percentage_of_time == other.percentage_of_time &&
        variants == other.variants
    end
    alias_method :==, :eql?

    private

    # Normalizes so values read back from json (string keys) compare equal to
    # values written in memory.
    def to_variants(value)
      return nil if value.nil? || value.empty?

      value.each_with_object({}) do |(name, weight), hash|
        hash[name.to_s] = Typecast.to_number(weight)
      end
    end
  end
end
