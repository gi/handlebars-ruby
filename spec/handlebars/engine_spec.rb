# frozen_string_literal: true

require "tempfile"

RSpec.describe Handlebars::Engine do
  let(:engine) { described_class.new(**engine_options) }
  let(:engine_context) { engine.instance_variable_get(:@context) }
  let(:engine_options) { {} }
  let(:render) { renderer.call(render_context, render_options) }
  let(:render_context) { { name: "Zach", age: 30 } }
  let(:render_options) { {} }
  let(:rendered) { "Hello, Zach!" }
  let(:renderer) { engine.compile(template, template_options) }
  let(:template) { "Hello, {{name}}!" }
  let(:template_options) { nil }

  it "has a version number" do
    expect(Handlebars::Engine::VERSION).to match(/^\d+\.\d+\.\d+(-.+)?(\+.+)?/)
  end

  describe "#initialize" do
    context "when `lazy` is `false`" do
      before do
        engine_options[:lazy] = false
      end

      it "creates the context" do
        expect(engine_context).to be_a(MiniRacer::Context)
      end

      it "loads Handlebars" do
        handlebars = engine_context.eval("!!Handlebars")
        expect(handlebars).to be(true)
      end
    end

    context "when `lazy` is `true`" do
      before do
        engine_options[:lazy] = true
      end

      it "does not create the context" do
        expect(engine_context).to be nil
      end
    end

    context "when `path` is defined" do
      let(:file) { Tempfile.open }

      before do
        engine_options[:path] = file.path
        file.write <<~HANDLEBARS
          var Handlebars = {
            compile: () => "compile",
            precompile: () => "precompile",
            template: () => "template",
            registerPartial: () => "registerPartial",
            unregisterPartial: () => "unregisterPartial",
            registerHelper: () => "registerHelper",
            unregisterHelper: () => "unregisterHelper",
            partials: {},
            VERSION: "VERSION",
          };
        HANDLEBARS
        file.rewind
      end

      after do
        file.close
      end

      it "loads the file contents" do
        expect(engine_context.eval("VERSION")).to eq("VERSION")
      end
    end
  end

  ###################################
  # Compilation
  ###################################

  shared_examples "renderer" do
    describe "#call" do
      it "is defined" do
        expect(renderer).to respond_to(:call).with(0..2).arguments
      end

      include_examples "rendering"
    end
  end

  shared_examples "rendering" do |error: false|
    if error
      it "raises an error" do
        expect { render }.to raise_error(MiniRacer::RuntimeError)
      end
    else
      it "renders the template" do
        expect(render).to eq(rendered)
      end
    end
  end

  describe "#compile" do
    let(:renderer) { engine.compile(template, template_options) }

    it "is defined" do
      expect(engine).to respond_to(:compile).with(1..2).arguments
    end

    describe "return value" do
      it_behaves_like "renderer"
    end
  end

  describe "#precompile" do
    let(:spec) { engine.precompile(template, template_options) }

    it "is defined" do
      expect(engine).to respond_to(:precompile).with(1..2).arguments
    end

    describe "return value" do
      it "is a string" do
        expect(spec).to be_a(String)
      end
    end
  end

  describe "#template" do
    let(:renderer) { engine.template(template_spec) }
    let(:template_spec) { engine.precompile(template, template_options) }

    it "is defined" do
      expect(engine).to respond_to(:template).with(1).argument
    end

    describe "return value" do
      it_behaves_like "renderer"
    end
  end

  ###################################
  # Runtime
  ###################################

  describe "#register_helper" do
    let(:name) { :helper }
    let(:function) { ->(_ctx, *_args, _opts) { rendered } }
    let(:template) { "{{#{name} name name=name}}" }

    before do
      engine.register_helper(name, function)
    end

    it "is defined" do
      expect(engine).to respond_to(:register_helper)
    end

    context "with positional parameters" do
      context "when function is argument" do
        before do
          engine.register_helper(name, function)
        end

        describe "rendering" do
          include_examples "rendering"
        end
      end

      context "when function is block" do
        before do
          engine.register_helper(name, &function)
        end

        describe "rendering" do
          include_examples "rendering"
        end
      end
    end

    context "with keyword parameters" do
      before do
        engine.register_helper(name => function)
      end

      describe "rendering" do
        include_examples "rendering"
      end
    end

    context "with a Ruby function" do
      before do
        allow(function).to receive(:call).with(any_args).and_call_original
      end

      describe "the first parameter" do
        it "is the context" do
          render_context.transform_keys!(&:to_s)
          args = [render_context, any_args, anything]
          render
          expect(function).to have_received(:call).with(*args)
        end
      end

      describe "the middle parameter(s)" do
        it "is the positional argument(s)" do
          args = [anything, *render_context.values_at(:name), anything]
          render
          expect(function).to have_received(:call).with(*args)
        end
      end

      describe "the last parameter" do
        it "is the options" do
          opts = include(
            "data" => kind_of(Hash),
            "hash" => { "name" => render_context[:name] },
            "name" => name.to_s,
          )
          args = [anything, any_args, opts]
          render
          expect(function).to have_received(:call).with(*args)
        end
      end

      context "with a block helper" do
        let(:template) { "{{##{name}}}help{{/#{name}}}" }

        describe "the options" do
          it "includes the main block function" do
            opts = include(
              "fn" => kind_of(MiniRacer::JavaScriptFunction),
            )
            args = [anything, any_args, opts]
            render
            expect(function).to have_received(:call).with(*args)
          end

          it "includes the else block function" do
            opts = include(
              "inverse" => kind_of(MiniRacer::JavaScriptFunction),
            )
            args = [anything, any_args, opts]
            render
            expect(function).to have_received(:call).with(*args)
          end
        end
      end
    end

    context "with a JavaScript function" do
      let(:function) {
        <<~JS
          function (...args) {
            args.unshift(this);
            return tester(...args);
          }
        JS
      }
      let(:tester) { ->(_ctx, *_args, _opts) { rendered } }

      before do
        allow(tester).to receive(:call).with(any_args).and_call_original
        engine_context.attach("tester", tester)
      end

      describe "rendering" do
        include_examples "rendering"
      end

      describe "`this`" do
        it "is the context" do
          render_context.transform_keys!(&:to_s)
          args = [render_context, any_args, anything]
          render
          expect(tester).to have_received(:call).with(*args)
        end
      end

      describe "the first parameter(s)" do
        it "is the positional argument(s)" do
          args = [anything, *render_context.values_at(:name), anything]
          render
          expect(tester).to have_received(:call).with(*args)
        end
      end

      describe "the last parameter" do
        it "is the options" do
          opts = include(
            "data" => kind_of(Hash),
            "hash" => { "name" => render_context[:name] },
            "name" => name.to_s,
          )
          args = [anything, any_args, opts]
          render
          expect(tester).to have_received(:call).with(*args)
        end
      end

      context "with a block helper" do
        let(:template) { "{{##{name} age}}function{{else}}inverse{{/#{name}}}" }
        let(:function) {
          <<~JS
            function (age, opts) {
              return age > 0 ? opts.fn() : opts.inverse();
            }
          JS
        }

        describe "the options" do
          it "includes the main block function" do
            render_context[:age] = 30
            expect(render).to eq("function")
          end

          it "includes the else block function" do
            render_context[:age] = 0
            expect(render).to eq("inverse")
          end
        end
      end
    end
  end

  describe "#unregister_helper" do
    let(:name) { :helper }
    let(:function) { ->(ctx, *args, opts) {} }
    let(:rendered) { "Missing helper: \"#{name}\"" }
    let(:template) { "{{#{name} name name=name}}" }

    before do
      engine.register_helper(name, &function)
      engine.unregister_helper(name)
    end

    it "is defined" do
      expect(engine).to respond_to(:unregister_helper)
    end

    describe "rendering" do
      include_examples "rendering", error: true
    end
  end

  describe "#register_partial" do
    let(:name) { :person }
    let(:partial) { "{{p.name}} is {{p.age}}" }
    let(:rendered) { "Zach is 30" }
    let(:template) { "{{> person p=.}}" }

    it "is defined" do
      expect(engine).to respond_to(:register_partial)
    end

    context "with positional parameters" do
      before do
        engine.register_partial(name, partial)
      end

      describe "rendering" do
        include_examples "rendering"
      end
    end

    context "with keyword parameters" do
      before do
        engine.register_partial(name => partial)
      end

      describe "rendering" do
        include_examples "rendering"
      end
    end
  end

  describe "#unregister_partial" do
    let(:name) { :person }
    let(:partial) { "" }
    let(:template) { "{{> person}}" }

    before do
      engine.register_partial(name, partial)
      engine.unregister_partial(name)
    end

    it "is defined" do
      expect(engine).to respond_to(:unregister_partial)
    end

    describe "rendering" do
      include_examples "rendering", error: true
    end
  end

  ###################################
  # Hooks
  ###################################

  describe "#register_helper_missing" do
    let(:name) { :helper }
    let(:function) { ->(_ctx, *_args, opts) { "Missing: #{opts["name"]}" } }
    let(:rendered) { "Missing: #{name}" }
    let(:template) { "{{#{name} name}}" }
    let(:type) { :basic }

    before do
      allow(function).to receive(:call).with(any_args).and_call_original
      engine.register_helper_missing(type, &function)
    end

    it "is defined" do
      expect(engine).to respond_to(:register_helper_missing)
    end

    describe "rendering" do
      describe "the first parameter" do
        it "is the context" do
          render_context.transform_keys!(&:to_s)
          args = [render_context, any_args, anything]
          render
          expect(function).to have_received(:call).with(*args)
        end
      end

      describe "the middle parameter(s)" do
        it "is the positional argument(s)" do
          args = [anything, *render_context.values_at(:name), anything]
          render
          expect(function).to have_received(:call).with(*args)
        end
      end

      describe "the last parameter" do
        it "is the options" do
          opts = include(
            "data" => kind_of(Hash),
            "hash" => {},
            "name" => name.to_s,
          )
          args = [any_args, opts]
          render
          expect(function).to have_received(:call).with(*args)
        end
      end

      include_examples "rendering"

      context "when called as a block" do
        let(:block_args) { [] }
        let(:template) { "{{##{name} #{block_args.join(" ")}}}{{/#{name}}}" }

        context "with no arguments" do
          let(:block_args) { [] }

          context "with no matching context value" do
            before do
              render_context.delete(name)
            end

            it "calls the helper" do
              render
              expect(function).to have_received(:call)
            end
          end

          context "with a matching context value" do
            before do
              render_context[name] = "missing"
            end

            it "does not call the helper" do
              render
              expect(function).not_to have_received(:call)
            end
          end
        end

        context "with some arguments" do
          let(:block_args) { ["name"] }

          context "with no matching context value" do
            before do
              render_context.delete(name)
            end

            it "calls the helper" do
              render
              expect(function).to have_received(:call)
            end
          end

          context "with a matching context value" do
            before do
              render_context[name] = "missing"
            end

            include_examples "rendering", error: true
          end
        end
      end

      describe "type: `block`" do
        let(:type) { :block }

        include_examples "rendering", error: true

        context "when called as a block" do
          let(:block_args) { [] }
          let(:template) { "{{##{name} #{block_args.join(" ")}}}{{/#{name}}}" }

          context "with no arguments" do
            let(:block_args) { [] }

            context "with no matching context value" do
              before do
                render_context.delete(name)
              end

              it "calls the helper" do
                render
                expect(function).to have_received(:call)
              end
            end

            context "with a matching context value" do
              before do
                render_context[name] = "missing"
              end

              it "calls the helper" do
                render
                expect(function).to have_received(:call)
              end
            end
          end

          context "with some arguments" do
            let(:block_args) { ["name"] }

            context "with no matching context value" do
              before do
                render_context.delete(name)
              end

              include_examples "rendering", error: true
            end

            context "with a matching context value" do
              before do
                render_context[name] = "missing"
              end

              include_examples "rendering", error: true
            end
          end
        end
      end
    end
  end

  describe "#unregister_helper_missing" do
    let(:name) { :helper }
    let(:function) { ->(ctx, *args, opts) {} }

    before do
      engine.register_helper_missing(&function)
      engine.unregister_helper_missing
    end

    it "is defined" do
      expect(engine).to respond_to(:unregister_helper_missing)
    end

    describe "rendering" do
      context "with arguments" do
        let(:template) { "{{#{name} name name=name}}" }

        include_examples "rendering", error: true
      end

      context "without arguments" do
        let(:rendered) { "" }
        let(:template) { "{{#{name}}}" }

        include_examples "rendering"
      end
    end
  end

  describe "#register_partial_missing" do
    let(:name) { :person }
    let(:function) { ->(_name) { partial } }
    let(:partial) { "{{p.name}} is {{p.age}}" }
    let(:rendered) { "Zach is 30" }
    let(:template) { "{{> #{name} p=.}}" }

    before do
      allow(function).to receive(:call).with(any_args).and_call_original
      engine.register_partial_missing(&function)
    end

    it "is defined" do
      expect(engine).to respond_to(:register_partial_missing)
    end

    describe "rendering" do
      describe "the first parameter" do
        it "is the name" do
          args = [name.to_s]
          render
          expect(function).to have_received(:call).with(*args)
        end
      end

      include_examples "rendering"
    end
  end

  describe "#unregister_partial_missing" do
    let(:name) { :person }
    let(:function) { ->(n) {} }
    let(:template) { "{{> #{name} p=.}}" }

    before do
      engine.register_partial_missing(&function)
      engine.unregister_partial_missing
    end

    it "is defined" do
      expect(engine).to respond_to(:unregister_partial_missing)
    end

    describe "rendering" do
      include_examples "rendering", error: true
    end
  end

  ###################################
  # Miscellaneous
  ###################################

  describe "#version" do
    it "is defined" do
      expect(engine).to respond_to(:version)
    end

    it "returns a version string" do
      expect(engine.version).to match(/^\d+\.\d+\.\d+$/)
    end
  end
end
