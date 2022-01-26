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

var registerHelper = (...args) => {
  const fn = args[args.length - 1];
  function wrapper(...args) {
    args.unshift(this);
    return fn(...args);
  }
  args[args.length - 1] = wrapper;
  return Handlebars.registerHelper(...args);
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
