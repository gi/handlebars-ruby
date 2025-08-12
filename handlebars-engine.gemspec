# frozen_string_literal: true

require_relative "lib/handlebars/engine/version"

Gem::Specification.new do |spec|
  spec.name = "handlebars-engine"
  spec.version = Handlebars::Engine::VERSION
  spec.authors = ["Zach Gianos"]
  spec.email = ["zach.gianos+git@gmail.com"]

  spec.summary = "A complete interface to Handlebars.js for Ruby."
  spec.description = <<-DESCRIPTION
    A complete interface to Handlebars.js for Ruby.

    Handlebars::Engine provides a complete Ruby API for the official JavaScript
    version of Handlebars, including the abilities to register Ruby blocks/procs
    as Handlebars helper functions and to dynamically register partials.

    It uses MiniRacer for the bridge between Ruby and the V8 JavaScript engine.

    Handlebars::Engine was created as a replacement for handlebars.rb.
  DESCRIPTION

  spec.homepage = "https://github.com/gi/handlebars-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"
  spec.metadata["github_repo"] = spec.homepage
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) {
    include_dirs = ["exe", "ext", "lib"]
    include_files = ["changelog", "license", "readme"]
    git_files = `git ls-files -z`.split("\x0")
    git_files.select { |f|
      f.match?(%r{^(#{include_dirs.join("|")})/}i) ||
        f.match?(/^(#{include_files.join("|")})(\.\w+)?/i)
    }
  }

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "handlebars-source"
  spec.add_dependency "mini_racer"
end
