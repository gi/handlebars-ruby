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
          begin
            context.eval("delete #{name}")
          rescue ThreadError # rubocop:disable Lint/SuppressedException
          end
        }
      end
    end
  end
end
