# Template2

`comerc:template2`

[MVVM](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel) for Meteor with  [Two-Way Binding](https://github.com/comerc/meteor-template-two-way-binding) via [Model Schema](https://github.com/aldeed/meteor-simple-schema).

## Intro

Fork of [TemplateController](https://github.com/meteor-space/template-controller):

>**Supports the best practices of writing Blaze templates**
>
>**Blaze is awesome** but writing the Js part of templates always
felt a bit awkward. This package just provides a very thin layer of syntactic
sugar on top of the standard API, so you can follow best practices outlined
in the [Blaze guide](http://guide.meteor.com/blaze.html#reusable-components)
more easily.

**Now you can turn this:**

```handlebars
You have clicked the button {{counter}} times.
<button>click</button>
```

```javascript
Template.hello.onCreated(function helloOnCreated() {
  // counter starts at 0
  this.counter = new ReactiveVar(0);
});

Template.hello.helpers({
  counter() {
    return Template.instance().counter.get();
  },
});

Template.hello.events({
  'click button'(event, instance) {
    // increment the counter when button is clicked
    instance.counter.set(instance.counter.get() + 1);
  },
});
```

**into that:**

```handlebars
You have clicked the button {{state.counter}} times.
<button>click</button>
```

```javascript
Template2.mixin('hello', {
  states: {
    counter: 0 // default value
  },
  events: {
    'click button'() {
      // increment the counter when button is clicked
      this.state.counter += 1;
    }
  }
});
```

## Key features
- Compatible with Blaze Template.
- Minimum changes for migration your great project to Template2.
- One time declaration of variables to model via html-input attribute.
- Validate input data and get doc for writing to model without coding.
- Support of  [SimpleSchema](https://github.com/aldeed/meteor-simple-schema), may be extended for support any other model  ([Astronomy](https://github.com/jagi/meteor-astronomy) etc.)

## How to run Demo

```
$ git clone https://github.com/comerc/meteor-template2.git
$ cd meteor-template2
$ meteor
```

...then [http://localhost:3000](http://localhost:3000)

## Installation

In your Meteor app directory, enter:

```
$ meteor add comerc:template2
```

## Basic Usage

```
$ meteor add aldeed:simple-schema
$ meteor add aldeed:collection2
```

```javascript
Posts = new Mongo.Collection('posts');

PostSchema = new SimpleSchema({
  value: {
    type: String,
    min: 3,
    defaultValue: '777'
  }
});

Posts.attachSchema(PostSchema);
```

```handlebars
<body>
  {{> hello param="123"}}
</body>

<template name="hello">
  <p><code>props.param</code> {{props.param}}</p>
  <p><code>state.value</code> {{state.value}}</p>
  <form>
    <input value-bind="value|debounce:300"/>
    <button type="submit">Submit</button>
  </form>
  <p>{{state.errorMessages}}</p>
</template>
```

```javascript
Template2.mixin('hello', {
  // Validate the properties passed to the template from parents
  propsSchema: new SimpleSchema({
    param: { type: String }
  }),
  // Setup Model Schema
  modelSchema: Posts.simpleSchema(),
  // Setup reactive template states
  states: {},
  // Helpers & Events work like before but <this> is always the template instance!
  helpers: {}, events: {}, actions: {},
  // Lifecycle callbacks work exactly like with standard Blaze
  onCreated() {},
  onRendered() {},
  onDestroyed() {},
});

// events declaration by old shool
Template.hello.eventsByInstance({
  'submit form': function(e) {
    e.preventDefault();
    // this - context of Template.instance()
    this.viewDoc(function(error, doc) {
      if (error) return;
      Posts.insert(doc);
    });
  }
});

// onRendered declaration by old shool
Template.hello.onRendered(function() {
  var self = this;
  this.autorun(function() {
    var doc = Posts.findOne();
    if (doc) {
      self.modelDoc(doc);
    }
  });
});
```

## API

### `onCreated`, `onRenderd`, `onDestroyed`
Work exactly the same as with standard Blaze.

### `events`, `helpers`
Work exactly the same as normal but `this` inside the handlers is always
a reference to the `Template.instance()`. In most cases that's what you want
and would expect. You can still access the data context via `this.data`.

### `propsSchema: { clean: Function, validate: Function }`

Any data passed to your component should be validated to avoid UI bugs
that are hard to find. You can pass any object to the `propsSchema` option, which
provides a `clean` and `validate` function. `clean` is called first and can
be used to cleanup the data context before validating it (e.g: adding default
properties, transforming values etc.). `validate` is called directly after
and should throw validation errors if something does not conform the schema.
This api is compatible but not limited to
[SimpleSchema](https://github.com/aldeed/meteor-simple-schema).

This is a best practice outlined in the
[Blaze guide - validate data context](http://guide.meteor.com/blaze.html#validate-data-context)
section. `Template2` does provide a bit more functionality though:
any property you define in the schema is turned into a template helper
that can be used as a reactive getter, also in the html template:

```javascript
Template2.mixin('hello', {
  propsSchema: new SimpleSchema({
    messageCount: {
      type: Number, // allows only integers!
      defaultValue: 0
    }
  })
});
```

```handlebars
<template name="hello">
  You have {{props.messageCount}} messages.
</template>
```

… and you can access the value of `messageCount` anywhere in helpers etc. with
`this.props.messageCount`

a parent template can provide the `messageCount` prop with standard Blaze:
```handlebars
<template name="parent">
  {{> hello messageCount=unreadMessagesCount}}
</template>
```

If the parent passes down anything else than an integer value for `messageCount`
our component will throw a nice validation error.

### `modelSchema: { schema: Function, newContext: Function }`

You can pass any object to the `modelSchema` option, which provides a `schema` and `newContext` function.

This api is compatible but not limited to
[SimpleSchema](https://github.com/aldeed/meteor-simple-schema).

### `states: { myProperty: defaultValue, … }`

Each state property you define is turned into a `ReactiveVar` and you can get
the value with `this.state.myProperty` and set it like a normal property
`this.state.myProperty = newValue`. The reason why we are not using
`ReactiveVar` directly is simple: we need a template helper to render it in
our html template! So `Template2` actually adds a `state` template
helper which returns `this.state` and thus you can render any state var in
your templates like this:

```handlebars
You have clicked the button {{state.counter}} times.
```

But you can also modify the state var easily in your Js code like this:

```javascript
events: {
  'click button'() {
    this.state.counter += 1;
  }
}
```

Since each state var is turned into a separate reactive var you do not run
into any reactivity issues with re-rendering too much portions of your template.

### `viewDoc(callback)`

Get doc via callback after clean and validation for save to model.

```javascript
var t = Template.instance();
t.viewDoc(function(error, doc) {
  if (error) return;
  Posts.insert(doc);
});
```

### `modelDoc(doc)`

Set doc from model to view.

```javascript
var t = Template.instance();
var doc = Posts.findOne();
t.modelDoc(doc);
```

## Two-Way Binding features

Described [here](https://github.com/comerc/meteor-template-two-way-binding).

## Configuration

### `Template2.setPropsCleanConfiguration(Object)`
Enables you to configure the props cleaning operation of libs like SimpleSchema. Checkout [SimpleSchema clean docs](https://github.com/aldeed/meteor-simple-schema#cleaning-data) to
see your options.

Here is one example why `removeEmptyStrings: true` is the default config:

```handlebars
{{> button label=(i18n 'button_label') }}
```
`i18n` might initially return an empty string for your translation.
This would cause an validation error because SimpleSchema removes empty strings by default when cleaning the data.

### `Template2.setModelCleanConfiguration(Object)`

The same as [previos](https://github.com/comerc/meteor-template2#template2setpropscleanconfigurationobject), but for model.

## TODO
- [ ] AstronomySchema (for compatible with SimpleSchema)
- [ ] Add `original` and `error`* helpers, like [useful:forms](https://github.com/usefulio/forms)  
- [ ] Wait for throttle & debounce before form submit
- [ ] Demo with [meteor7](https://github.com/daveeel/meteor7)
- [ ] Actions, like [blaze-magic-events](https://github.com/themeteorites/blaze-magic-events)
- [x] Template.hello.init(config) to Template2.mixin(template, config)
- [ ] Remove underscore dependence

## Inspired by

- [Aurelia](http://aurelia.io/)
- [Vue](https://vuejs.org/guide/#Two-way-Binding)
- [ReactLink](https://facebook.github.io/react/docs/two-way-binding-helpers.html)
- [Blaze](https://github.com/meteor/meteor/tree/devel/packages/blaze)
- [aldeed:autoform](https://github.com/aldeed/meteor-autoform)
- [manuel:viewmodel](https://github.com/ManuelDeLeon/viewmodel)
- [nov1n:reactive-bind](https://github.com/nov1n/reactive-bind)
- [space:template-controller](https://github.com/meteor-space/template-controller)
- [themeteorites:blaze-magic-events](https://github.com/themeteorites/blaze-magic-events)
- [moberegger:validated-template](https://github.com/MichaelOber/validated-template)
- [voidale:helpers-everywhere](https://github.com/voidale/meteor-helpers-everywhere)
- [useful:blaze-state](https://github.com/usefulio/blaze-state)
- [useful:forms](https://github.com/usefulio/forms)
- [ouk:template-destruct](https://github.com/andrejsm/meteor-template-destruct)
- [mpowaga:template-schema](https://github.com/mpowaga/meteor-template-schema)
- [peerlibrary:blaze-components](https://github.com/peerlibrary/meteor-blaze-components)
- [aldeed:template-extension](https://github.com/aldeed/meteor-template-extension)
- [meteorhacks:flow-components](https://github.com/meteorhacks/flow-components)
- [kadira:blaze-plus](https://github.com/kadirahq/blaze-plus)
- [templates:forms](https://github.com/meteortemplates/forms)

<!-- ## Refs
- https://github.com/jagi/meteor-astronomy/issues/1
- https://github.com/jagi/meteor-astronomy/issues/112 -->

## License
Licensed under the MIT license.
