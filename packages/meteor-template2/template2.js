class ReactiveObject {
  constructor(t, properties = {}) {
    this.addProperties(properties);
  }
  addProperty(key, defaultValue = null) {
    const property = new ReactiveVar(defaultValue);
    Object.defineProperty(this, key, {
      get: () => { return property.get(); },
      set: (value) => { property.set(value); }
    });
  }
  addProperties(properties = {}) {
    for (let key of Object.keys(properties)) {
      this.addProperty(key, properties[key]);
    }
  }
}

const bindToTemplateInstance = function(handler) {
  return function() {
    return handler.apply(Template.instance(), arguments);
  };
};

const bindAllToTemplateInstance = function(handlers) {
  for (let key of Object.keys(handlers)) {
    handlers[key] = bindToTemplateInstance(handlers[key]);
  }
  return handlers;
};

const propertyValidatorRequired = function() {
  let error = new Error(
    '<data> must be a validator with #clean and #validate methods (see: SimpleSchema)'
  );
  error.name = 'PropertyValidatorRequired';
  return error;
};

const propertyValidationError = function(error, templateName) {
  error.name = 'PropertyValidationError';
  error.message = `in <${templateName}> ` + error.message;
  return error;
};

let propsCleanConfiguration = {};

Blaze.TemplateInstance.prototype.state = new ReactiveObject();

Blaze.TemplateInstance.prototype.states = function(states) {
  if (!states) return;
  let helpers = {};
  for (let key of Object.keys(states)) {
    this.state.addProperty(key, states[key]);
    helpers[key] = function() {
      return Template.instance().state[key];
    };
  }
  this.view.template.helpers(helpers);
  return this;
}

Blaze.TemplateInstance.prototype.schema = function(schema) {
  if (!(schema && schema.validate && schema.clean)) {
    throw propertyValidatorRequired();
  }
  // Setup validated reactive props passed from the outside
  this.props = new ReactiveObject();
  let helpers = {};
  helpers.props = function() { return Template.instance().props; };
  this.view.template.helpers(helpers);
  this.autorun(() => {
    let currentData = Template.currentData() || {};
    schema.clean(currentData, propsCleanConfiguration);
    try {
      schema.validate(currentData);
    } catch (error) {
      throw propertyValidationError(error, this.view.name);
    }
    for (let key of Object.keys(currentData)) {
      let value = currentData[key];
      if (!this.props.hasOwnProperty(key)) {
        this.props.addProperty(key, value);
      } else {
        this.props[key] = value;
      }
    }
  });
  return this;
}

Blaze.TemplateInstance.prototype.helpers = function (helpers) {
  this.view.template.helpers(bindAllToTemplateInstance(helpers));
  return this;
}

Blaze.TemplateInstance.prototype.events = function (eventMap) {
  this.view.template.events(bindAllToTemplateInstance(eventMap));
  return this;
}

Blaze.Template.prototype.helpersByInstance = function (helpers) {
  this.helpers(bindAllToTemplateInstance(helpers));
}

Blaze.Template.prototype.eventsByInstance = function (eventMap) {
  this.events(bindAllToTemplateInstance(eventMap));
}

// We have to make it a global to support Meteor 1.2.x
Template2 = {};

Template2.setPropsCleanConfiguration = (config) => {
  propsCleanConfiguration = config;
};
