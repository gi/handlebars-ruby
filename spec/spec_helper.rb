# frozen_string_literal: true

require_relative "spec_coverage"

require "handlebars/engine"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = "spec/reports/status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.add_formatter("documentation")
  config.add_formatter("RspecJunitFormatter", "spec/reports/rspec.xml")
end
