# frozen_string_literal: true

RSpec.describe Handlebars::Engine do
  it "has a version number" do
    expect(Handlebars::Engine::VERSION).not_to be(nil)
  end
end
