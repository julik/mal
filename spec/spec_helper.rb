require 'rspec'

RSpec.configure do |config|
  config.order = 'random'
end

require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
end
require_relative '../lib/mal'
