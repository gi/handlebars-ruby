# frozen_string_literal: true

require "handlebars/source"
require "json"
require "mini_racer"
require "securerandom"
require_relative "engine/function"
require_relative "engine/version"

module Handlebars
  # The Handlebars engine.
  #
  # This API follows the JavaScript API as closely as possible:
  # https://handlebarsjs.com/api-reference/.
  class Engine
    Error = MiniRacer::RuntimeError

    # Creates a new instance.
    #
    # @param lazy [true, false] immediately loads and initializes the JavaScript
    #   environment.
    # @param path [String, nil] the path to the version of Handlebars to load.
    #   If `nil`, the contents of `Handlebars::Source.bundled_path` is loaded.
    def initialize(lazy: false, logger: nil, path: nil)
      @logger = logger
      @path = path
      init! unless lazy
    end

    ###################################
    # Compilation
    ###################################

    # Compiles a template so it can be executed immediately.
    #
    # @param template [String] the template string to compile
    # @param options [Hash] the options
    # @return [Proc] the template function to call
    # @see https://handlebarsjs.com/api-reference/compilation.html#handlebars-compile-template-options
    def compile(*args)
      call(__method__, args, assign: true)
    end

    # Precompiles a given template so it can be executed without compilation.
    #
    # @param template [String] the template string to precompiled
    # @param options [Hash] the options
    # @return [String] the precompiled template spec
    # @see https://handlebarsjs.com/api-reference/compilation.html#handlebars-precompile-template-options
    def precompile(*args)
      call(__method__, args)
    end

    # Sets up a template that was precompiled with `precompile`.
    #
    # @param spec [String] the precompiled template spec
    # @return [Proc] the template function to call
    # @see #precompile
    # @see https://handlebarsjs.com/api-reference/compilation.html#handlebars-template-templatespec
    def template(*args)
      call(__method__, args, assign: true)
    end

    ###################################
    # Runtime
    ###################################

    # Registers helpers accessible by any template in the environment.
    #
    # The function can be either a proc or a string:
    # * When the function is a proc, it can be either passed in as a normal
    #   parameter or as a block.
    # * When the function is a string, it is interpreted as a JavaScript
    #   function.
    #
    # @param name [String, Symbol] the name of the helper
    # @param function [Proc, String] the helper function
    # @yieldparam context [Hash] the current context
    # @yieldparam arguments [Object] the arguments (optional)
    # @yieldparam options [Hash] the options hash (optional)
    # @see https://handlebarsjs.com/api-reference/runtime.html#handlebars-registerhelper-name-helper
    def register_helper(name = nil, function = nil, **helpers, &block)
      helpers[name] = block || function if name
      helpers.each do |n, f|
        case f
        when Proc
          attach(n, &f)
          evaluate("registerRbHelper('#{n}', #{n})")
        when String, Symbol
          evaluate("registerJsHelper('#{n}', #{f})")
        end
      end
    end

    # Unregisters a previously registered helper.
    #
    # @param name [String, Symbol] the name of the helper
    # @see https://handlebarsjs.com/api-reference/runtime.html#handlebars-unregisterhelper-name
    def unregister_helper(name)
      call(:unregisterHelper, [name])
    end

    # Registers partials accessible by any template in the environment.
    #
    # @param name [String, Symbol] the name of the partial
    # @param partial [String] the partial template
    # @see https://handlebarsjs.com/api-reference/runtime.html#handlebars-registerpartial-name-partial
    def register_partial(name = nil, partial = nil, **partials)
      partials[name] = partial if name
      call(:registerPartial, [partials])
    end

    # Unregisters a previously registered partial.
    #
    # @param name [String, Symbol] the name of the partial
    # @see https://handlebarsjs.com/api-reference/runtime.html#handlebars-unregisterpartial-name
    def unregister_partial(name)
      call(:unregisterPartial, [name])
    end

    ###################################
    # Hooks
    ###################################

    # Registers the hook called when a mustache or a block-statement is missing.
    #
    # @param type [Symbol] the type of hook to register (`:basic` or `:block`)
    # @yieldparam arguments [Object] the arguments (optional)
    # @yieldparam options [Hash] the options hash (optional)
    # @see https://handlebarsjs.com/guide/hooks.html#helpermissing
    def register_helper_missing(type = :basic, &block)
      name = helper_missing_name(type)
      register_helper(name, &block)
    end

    # Unregisters the previously registered hook.
    #
    # @param type [Symbol] the type of hook to register (`:basic` or `:block`)
    # @see https://handlebarsjs.com/guide/hooks.html#helpermissing
    def unregister_helper_missing(type = :basic)
      name = helper_missing_name(type)
      unregister_helper(name)
    end

    # Registers the hook called when a partial is missing.
    #
    # Note: This is not a part of the offical Handlebars API. It is provided for
    # convenience.
    #
    # @yieldparam name [String] the name of the undefined partial
    def register_partial_missing(&block)
      attach(:partialMissing, &block)
    end

    # Unregisters the previously registered hook.
    def unregister_partial_missing
      evaluate("delete partialMissing")
    end

    ###################################
    # Miscellaneous
    ###################################

    # Returns the version of Handlebars.
    #
    # @return [String] the Handlebars version.
    def version
      evaluate("VERSION")
    end

    ###################################
    # Private
    ###################################

    private

    def attach(name, &block)
      init!
      @logger&.debug { "[handlebars] attaching #{name}" }
      @context.attach(name.to_s, block)
    end

    def call(name, args, assign: false, eval: false)
      init!
      name = name.to_s

      @logger&.debug { "[handlebars] calling #{name} with args #{args}" }

      if assign || eval
        call_via_eval(name, args, assign: assign)
      else
        @context.call(name, *args)
      end
    end

    def call_via_eval(name, args, assign: false)
      args = js_args(args)

      var = assign ? "v#{SecureRandom.alphanumeric}" : nil

      code = "#{name}(#{args.join(", ")})"
      code = "#{var} = #{code}" if var

      result = evaluate(code)

      if var && result.is_a?(MiniRacer::JavaScriptFunction)
        result = Function.new(@context, var)
      end

      result
    end

    def evaluate(code)
      @logger&.debug { "[handlebars] evaluating #{code}" }
      @context.eval(code)
    end

    def helper_missing_name(type)
      case type
      when :basic
        :helperMissing
      when :block
        :blockHelperMissing
      end
    end

    def init!
      return if @init

      @logger&.debug { "[handlebars] initializing" }

      @context = MiniRacer::Context.new
      @context.attach(
        "console.log",
        ->(*args) { @logger&.debug { "[handlebars] #{args.join(" ")}" } },
      )
      @context.load(@path || ::Handlebars::Source.bundled_path)
      @context.load(File.absolute_path("engine/init.js", __dir__))

      @logger&.debug { "[handlebars] initialized" }

      @init = true
    end

    def js_args(args)
      args.map { |arg| JSON.generate(arg) }
    end
  end
end
