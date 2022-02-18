# frozen_string_literal: true

module Handlebars
  class Engine
    # A proxy for a JavaScript function defined in the context.
    class Function
      def initialize(context, name)
        @context = context
        @name = name
      end

      def call(*args)
        @context.call(@name, *args)
      end
    end
  end
end
