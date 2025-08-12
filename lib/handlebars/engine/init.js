var {
  compile,
  precompile,
  registerPartial,
  unregisterPartial,
  registerHelper,
  unregisterHelper,
  VERSION,
} = Handlebars;

var template = (spec) => {
  eval(`spec = ${spec}`);
  return Handlebars.template(spec);
};

var registerPartial = Handlebars.registerPartial.bind(Handlebars);
var unregisterPartial = Handlebars.unregisterPartial.bind(Handlebars);

var registerJsHelper = Handlebars.registerHelper.bind(Handlebars);

var registerRbHelper = (name, fn) => {
  function wrapper(...args) {
    // Ruby cannot access the `this` context, so pass it as the first argument.
    args.unshift(this);
    const { ...options } = args[args.length-1];
    Object.entries(options).forEach(([key, value]) => {
      if (typeof value === "function") {
        // functions are cannot be passed back to Ruby
        options[key] = "function";
      }
    });
    args[args.length-1] = options
    return fn(...args);
  }
  return registerJsHelper(name, wrapper);
};

var unregisterHelper = Handlebars.unregisterHelper.bind(Handlebars);

var partialMissing;

const partialsHandler = {
  get(partials, name) {
    const partial = partials[name] ?? partialMissing?.(name);
    if (partial) {
      partials[name] = partial;
    }
    return partial;
  },
};

Handlebars.partials = new Proxy(Handlebars.partials, partialsHandler);
