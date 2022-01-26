# Handlebars::Engine

[![Gem Version](https://badge.fury.io/rb/handlebars-engine.svg)](https://rubygems.org/gems/handlebars-engine)
[![Build Status](https://github.com/gi/handlebars-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/gi/handlebars-ruby/actions/workflows/ci.yml)
[![Test Coverage](https://api.codeclimate.com/v1/badges/45d98ad9e12ee3384161/test_coverage)](https://codeclimate.com/github/gi/handlebars-ruby/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/45d98ad9e12ee3384161/maintainability)](https://codeclimate.com/github/gi/handlebars-ruby/maintainability)
[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE.txt)

A simple interface to [Handlebars.js](https://handlebarsjs.com) for Ruby.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'handlebars-engine'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install handlebars-engine

## Usage

### Quick Start

```ruby
handlebars = Handlebars::Engine.new
template = handlebars.compile("{{firstname}} {{lastname}}")
template.call({ firstname: "Yehuda", lastname: "Katz" })
# => "Yehuda Katz"
```

### Custom Helpers

Handlebars helpers can be accessed from any context in a template. You can
register a helper with the `register_helper` method:

```ruby
handlebars = Handlebars::Engine.new
handlebars.register_helper(:loud) do |ctx, arg, opts|
  arg.upcase
end
template = handlebars.compile("{{firstname}} {{loud lastname}}")
template.call({ firstname: "Yehuda", lastname: "Katz" })
# => "Yehuda KATZ"
```

#### Helper Arguments

Helpers receive the current context as the first argument of the block.

```ruby
handlebars = Handlebars::Engine.new
handlebars.register_helper(:full_name) do |ctx, opts|
  "#{ctx["firstname"]} #{ctx["lastname"]}"
end
template = handlebars.compile("{{full_name}}")
template.call({ firstname: "Yehuda", lastname: "Katz" })
# => "Yehuda Katz"
```

Any arguments to the helper are included as individual positional arguments.

```ruby
handlebars = Handlebars::Engine.new
handlebars.register_helper(:join) do |ctx, *args, opts|
  args.join(" ")
end
template = handlebars.compile("{{join firstname lastname}}")
template.call({ firstname: "Yehuda", lastname: "Katz" })
# => "Yehuda Katz"
```

The last argument is a hash of options.

See https://handlebarsjs.com/guide/#custom-helpers.

### Block Helpers

See https://handlebarsjs.com/guide/#block-helpers.

### Partials

Handlebars partials allow for code reuse by creating shared templates.

You can register a partial using the `register_partial` method:

```ruby
handlebars = Handlebars::Engine.new
handlebars.register_partial(:person, "{{person.name}} is {{person.age}}.")
template = handlebars.compile("{{> person person=.}}")
template.call({ name: "Yehuda Katz", age: 20 })
# => "Yehuda Katz is 20."
```

See https://handlebarsjs.com/guide/#partials.
See https://handlebarsjs.com/guide/partials.html.

### Hooks

#### Helper Missing

This hook is called for a mustache or a block-statement when
* a simple mustache-expression is not a registered helper, *and*
* it is not a property of the current evaluation context.

You can add custom handling for those situations by registering a helper with
the `register_helper_missing` method:

```ruby
handlebars = Handlebars::Engine.new
handlebars.register_helper_missing do |ctx, *args, opts|
  "Missing: #{opts["name"]}(#{args.join(", ")})"
end

template = handlebars.compile("{{foo 2 true}}")
template.call
# => "Missing: foo(2, true)"

template = handlebars.compile("{{#foo true}}{{/foo}}")
template.call
# => "Missing: foo(true)"
```

See https://handlebarsjs.com/guide/hooks.html#helpermissing.

##### Blocks

This hook is called for a block-statement when
* a block-expression calls a helper that is not registered, *and*
* the name is a property of the current evaluation context.

You can add custom handling for those situations by registering a helper with
the `register_helper_missing` method (with a `:block` argument):

```ruby
handlebars = Handlebars::Engine.new
handlebars.register_helper_missing(:block) do |ctx, *args, opts|
  "Missing: #{opts["name"]}(#{args.join(", ")})"
end

template = handlebars.compile("{{#person}}{{name}}{{/person}}")
template.call({ person: { name: "Yehuda Katz" } })
# => "Missing: person"
```

See https://handlebarsjs.com/guide/hooks.html#blockhelpermissing.

#### Partial Missing

This hook is called for a partial that is not registered.

```ruby
handlebars = Handlebars::Engine.new
handlebars.register_partial_missing do |name|
  "partial: #{name}"
end
```

Note: This is not a part of the offical Handlebars API. It is provided for
convenience.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for more details.

## Contributing

Bug reports and pull requests are welcome on GitHub:
https://github.com/gi/handlebars-ruby.

See [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
