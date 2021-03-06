# Template2

`comerc:template2`

[MVVM](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel) for Meteor with  [Two-Way Binding](https://github.com/comerc/meteor-template-two-way-binding) via [Model Schema](https://github.com/aldeed/meteor-simple-schema).

## Table of Contents

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

  - [Intro](#intro)
  - [Key features](#key-features)
  - [How to run Demo](#how-to-run-demo)
  - [Installation](#installation)
  - [Basic Usage](#basic-usage)
  - [API](#api)
    - [`onCreated`, `onRendered`, `onDestroyed`](#oncreated-onrendered-ondestroyed)
    - [`events`, `helpers`](#events-helpers)
    - [`propsSchema: { clean: Function, validate: Function }`](#propsschema--clean-function-validate-function-)
    - [`modelSchema: { schema: Function, newContext: Function }`](#modelschema--schema-function-newcontext-function-)
    - [`states: { myProperty: defaultValue, … }`](#states--myproperty-defaultvalue-%E2%80%A6-)
    - [`viewDoc(callback)`](#viewdoccallback)
    - [`modelDoc(doc)`](#modeldocdoc)
  - [Two-Way Binding features](#two-way-binding-features)
  - [Configuration](#configuration)
    - [`Template2Config.propsClean`](#template2configpropsclean)
    - [`Template2Config.modelClean`](#template2configmodelclean)
  - [TODO](#todo)
  - [Inspired by](#inspired-by)
  - [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Intro

Fork of TemplateController ([what difference](https://github.com/meteor-space/template-controller/issues/35)):

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
Template2('hello', {
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

>Yeah i have used [ViewModel](http://viewmodel.org) before – it's also nice, and there are also [Blaze Components](https://github.com/peerlibrary/meteor-blaze-components). My only "problem" with these existing packages is that they introduce new concepts on top of the standard Blaze api. I just wanted less boilerplate and that best practices like setting up ReactiveVars, validating properties passed to a template or accessing Template.instance() become a no-brainer for the whole team.
>
>The idea for this package came up during a Meteor training with some Devs where realized how complicated it is to explain the best practices with Blaze and that they had a ton of questions like "how can i access the template instance in helpers / event handlers" or "how does a template manage state" – which is so basic that it should be the easiest thing in the world.

## Key features
- Compatible with Blaze Template - we love it.
- Minimum changes for migration your great project to Template2.
- One time declaration of variables to Model via `<input value-bind>` attribute.
- Validate input data and get doc for writing to Model without coding.
- Support of  [SimpleSchema](https://github.com/aldeed/meteor-simple-schema), may be extended for support any other Model  ([Astronomy](https://github.com/jagi/meteor-astronomy) etc.)
- Usage of Two-Way Binding Features without Model.

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
  myValue: {
    type: String,
    min: 3,
    defaultValue: '777'
  }
});

Posts.attachSchema(PostSchema);
```

```handlebars
<body>
  {{> hello myParam="123"}}
</body>

<template name="hello">
  <p><code>props.myParam</code> {{props.myParam}}</p>
  <p><code>state.myValue</code> {{state.myValue}}</p>
  <form>
    <input value-bind="myValue"/>
    <button type="submit">Submit</button>
  </form>
  <p>{{state.errorMessages}}</p>
</template>
```

```javascript
Template2('hello', {
  // Validate the properties passed to the template from parents
  propsSchema: new SimpleSchema({
    param: { type: String }
  }),
  // Setup Model Schema
  modelSchema: Posts.simpleSchema(),
  // Setup reactive template states
  states: {},
  // Helpers & Events work like before but <this> is always the template instance!
  helpers: {}, events: {},
  // Lifecycle callbacks work exactly like with standard Blaze
  onCreated() {}, onRendered() {}, onDestroyed() {},
});

// events declaration by old style, but with context by Template.instance()
Template.hello.eventsByInstance({
  'submit form': function(e) {
    e.preventDefault();
    // Get doc after clean and validation for save to model
    this.viewDoc(function(error, doc) {
      if (error) return;
      Posts.insert(doc);
    });
  }
});

// onRendered declaration by old style may also be used
Template.hello.onRendered(function() {
  var self = this;
  this.autorun(function() {
    var doc = Posts.findOne();
    if (doc) {
      // Set doc from model to view
      self.modelDoc(doc);
    }
  });
});
```

## API

### `onCreated`, `onRendered`, `onDestroyed`
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
Template2('hello', {
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

### `Template2Config.propsClean`
Enables you to configure the props cleaning operation of libs like SimpleSchema. Checkout [SimpleSchema clean docs](https://github.com/aldeed/meteor-simple-schema#cleaning-data) to
see your options.

Here is one example why `removeEmptyStrings: true` is the default config:

```handlebars
{{> button label=(i18n 'button_label') }}
```
`i18n` might initially return an empty string for your translation.
This would cause an validation error because SimpleSchema removes empty strings by default when cleaning the data.

### `Template2Config.modelClean`

The same as [previos](https://github.com/comerc/meteor-template2#template2configpropsclean), but for model.

## TODO
- [ ] AstronomySchema (for compatible with SimpleSchema)
- [ ] Add `original` and `error`* helpers, like [useful:forms](https://github.com/usefulio/forms)  
- [ ] Wait for throttle & debounce before form submit
- [ ] Demo with [meteor7](https://github.com/daveeel/meteor7)
- [ ] Actions, like [blaze-magic-events](https://github.com/themeteorites/blaze-magic-events)
- [ ] Remove underscore dependence
- [x] [Demo](https://github.com/comerc/meteor-mvvm-mdl-demo) with [Material Design Lite](https://getmdl.io/)
- [x] Remove helpers `propsOf` and `stateOf`, we may use `{{state.[field-name]}}`
- [ ] [Dependencies](https://github.com/ermouth/jQuery.my/#dependencies)
- [ ] [Conditional formatting and disabling](https://github.com/ermouth/jQuery.my/#conditional-formatting-and-disabling)

## Change Log
### 1.5.0
- `Template2.mixin()` rename to `Template2()`
- `Template2.setPropsCleanConfiguration(Object)` rename to `Template2Config.propsClean`
- `Template2.setModelCleanConfiguration(Object)` rename to `Template2Config.modelClean`

## Inspired by

- [jQuery.my](https://github.com/ermouth/jQuery.my)
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
MIT
