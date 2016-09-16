require 'rspec'

RSpec.configure do |config|
  config.order = 'random'
end

require 'simplecov'
SimpleCov.start
require_relative '../lib/mal'
