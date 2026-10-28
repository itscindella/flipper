require 'bundler/setup'
require 'flipper'

class User < Struct.new(:id)
  include Flipper::Identifier
end

users = (1..10_000).map { |n| User.new(n) }

# Run the experiment for 50% of actors. Variants only apply to actors the
# feature is enabled for; everyone else gets nil.
Flipper.enable_percentage_of_actors :checkout, 50
Flipper.enable_variants :checkout, control: 50, one_page: 30, express: 20

counts = Hash.new(0)
users.each { |user| counts[Flipper.variant(:checkout, user)] += 1 }

puts "Variants: #{Flipper.variants(:checkout).inspect}"
counts.sort_by { |variant, _| variant.to_s }.each do |variant, count|
  puts "#{(variant || 'not enrolled').to_s.ljust(14)} #{count}"
end

# Variants are kept when fully enabling or disabling the feature.
Flipper.enable :checkout
puts "After full enable: #{Flipper.variants(:checkout).inspect}"

begin
  Flipper.enable_variants :checkout, control: 50, one_page: 30
rescue ArgumentError => e
  puts "Rejected: #{e.message}"
end
