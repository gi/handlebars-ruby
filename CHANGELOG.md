# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.2] - 2022-02-17

### Changed
- `engine`: fixed issue with memory leak ([#15](https://github.com/gi/handlebars-ruby/pull/15))

## [0.3.1] - 2022-02-04

### Added
- `engine`: added `Error` class
- `specs`: added tests for (pre)compiling with options

### Changed
- `gem`/`readme`: updated description

## [0.3.0] - 2022-01-31

### Added
- `initialize`: add path parameter ([#5](https://github.com/gi/handlebars-ruby/pull/5))
- `register_helper`: accept multiple helpers as keyword parameters ([#6](https://github.com/gi/handlebars-ruby/pull/6))
- `register_helper`: accept javascript function as string ([#7](https://github.com/gi/handlebars-ruby/pull/7))
- `ci`: verify gem builds ([#8](https://github.com/gi/handlebars-ruby/pull/8))
- `require`: allow loading from `handlebars-engine` and `handlebars/engine` ([#8](https://github.com/gi/handlebars-ruby/pull/8))

## [0.2.0] - 2022-01-27

This is the initial implementation, wrapping the JavaScript Handlebars.

### Added
- `Handlebars::Engine#compile`
- `Handlebars::Engine#precompile`
- `Handlebars::Engine#template`
- `Handlebars::Engine#register_helper`
- `Handlebars::Engine#unregister_helper`
- `Handlebars::Engine#register_partial`
- `Handlebars::Engine#unregister_partial`
- `Handlebars::Engine#register_helper_missing`
- `Handlebars::Engine#unregister_helper_missing`
- `Handlebars::Engine#register_partial_missing`
- `Handlebars::Engine#unregister_partial_missing`
- `Handlebars::Engine#version`

## [0.1.0] - 2022-01-13

This is the initial package.

### Added
- gem init
