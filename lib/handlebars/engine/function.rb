# frozen_string_literal: true

module Handlebars
  class Engine
    # A proxy for a JavaScript function defined in the context.
    class Function
      def initialize(context, name)
        @context = context
        @name = name
        ObjectSpace.define_finalizer(self, self.class.finalizer(context, name))
      end

      def call(*args)
        @context.call(@name, *args)
      end

      def self.finalizer(context, name)
        proc {
          context.eval("delete #{name}")
        }
      end
    end
  end
end
