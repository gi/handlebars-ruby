# frozen_string_literal: true

module Handlebars
  class Engine
    # A proxy for a JavaScript function defined in the context.
    class Function
      def initialize(context, name, logger: nil)
        @context = context
        @logger = logger
        @name = name
      end

      def call(*args)
        @logger&.debug { "[handlebars] calling #{@name} with args #{args}" }
        @context.call(@name, *args)
      end
    end
  end
end
