class ReactiveObject {
  constructor(properties = {}) {
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

// Init props
Blaze.TemplateInstance.prototype.propsSchema = function(schema) {
  // Setup validated reactive props passed from the outside
  if (!(schema && schema.validate && schema.clean)) {
    throw propertyValidatorRequired();
  }
  this.__propsSchema = schema;
  if (!this.props) {
    this.props = new ReactiveObject();
    let helpers = {};
    // helpers.props = function(variable) { return Template.instance().props[variable]; };
    helpers.props = function() { return Template.instance().props; };
    this.view.template.helpers(helpers);
    this.autorun(() => {
      let currentData = Template.currentData() || {};
      this.__propsSchema.clean(currentData, propsCleanConfiguration);
      try {
        this.__propsSchema.validate(currentData);
      } catch (error) {
        throw propertyValidationError(error, this.view.name);
      }
      for (let key of Object.keys(currentData)) {
        let value = currentData[key];
        if (this.props.hasOwnProperty(key)) {
          this.props[key] = value;
        } else {
          this.props.addProperty(key, value);
        }
      }
    });
  }
  return this;
}

// Init states
Blaze.TemplateInstance.prototype.states = function(states) {
  if (!states) throw new Error('property states required');
  if (!this.state) {
    this.state = new ReactiveObject();
    let helpers = {};
    // helpers.state = function(variable) { return Template.instance().state[variable]; };
    helpers.state = function() { return Template.instance().state; };
    this.view.template.helpers(helpers);
  }
  for (let key of Object.keys(states)) {
    let value = states[key];
    if (this.state.hasOwnProperty(key)) {
      this.state[key] = value;
    } else {
      this.state.addProperty(key, value);
    }
  }
  return this;
}

Blaze.TemplateInstance.prototype.helpers = function(helpers) {
  this.view.template.helpers(bindAllToTemplateInstance(helpers));
  return this;
}

Blaze.TemplateInstance.prototype.events = function(eventMap) {
  this.view.template.events(bindAllToTemplateInstance(eventMap));
  return this;
}

Blaze.Template.prototype.helpersByInstance = function(helpers) {
  this.helpers(bindAllToTemplateInstance(helpers));
}

Blaze.Template.prototype.eventsByInstance = function(eventMap) {
  this.events(bindAllToTemplateInstance(eventMap));
}

// We have to make it a global to support Meteor 1.2.x
Template2 = {};

Template2.setPropsCleanConfiguration = (config) => {
  propsCleanConfiguration = config;
};

// old = Blaze.Template.prototype.events;
//
// Blaze.Template.prototype.events = function() {
//   console.log('event');
//   old.apply(this, arguments);
// }
