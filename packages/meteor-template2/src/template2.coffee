bindToTemplateInstance = (handler) ->
  return ->
    handler.apply Template.instance(), arguments

bindAllToTemplateInstance = (handlers) ->
  for key of handlers
    handlers[key] = bindToTemplateInstance(handlers[key]);
  return handlers

propertyValidatorRequired = ->
  error = new Error('<data> must be a validator with #clean and #validate methods (see: SimpleSchema)')
  error.name = 'PropertyValidatorRequired'
  return error

propertyValidationError = (error, templateName) ->
  error.name = 'PropertyValidationError'
  error.message = "in <#{templateName}> #{error.message}"
  return error

# Init props
Blaze.TemplateInstance.prototype.propsSchema = (schema) ->
  # Setup validated reactive props passed from the outside
  if not (schema and schema.validate and schema.clean)
    throw propertyValidatorRequired()
  @__propsSchema = schema
  if not @props
    @props = new ReactiveObject
    helpers = {}
    helpers.props = ->
      Template.instance().props
    @view.template.helpers helpers
    @autorun =>
      currentData = Template.currentData() or {}
      @__propsSchema.clean currentData, Template2Config.propsClean
      try
        @__propsSchema.validate currentData
      catch error
        throw propertyValidationError(error, @view.name)
      for key, value of currentData
        if @props.hasOwnProperty(key)
          @props[key] = value
        else
          @props.addProperty key, value
  return @

# Init state
Blaze.TemplateInstance.prototype.states = (states) ->
  if not states
    throw new Error('property states required')
  if not @state
    @state = new ReactiveObject
    helpers = {}
    helpers.state = ->
      Template.instance().state
    @view.template.helpers helpers
  for key, value of states
    if @state.hasOwnProperty(key)
      @state[key] = value
    else
      @state.addProperty key, value
  return @

# Init actions
Blaze.TemplateInstance.prototype.actions = (actions) ->
  # not implemented yet
  return @

Blaze.TemplateInstance.prototype.helpers = (helpers) ->
  @view.template.helpers bindAllToTemplateInstance(helpers)
  return @

Blaze.TemplateInstance.prototype.events = (eventMap) ->
  @view.template.events bindAllToTemplateInstance(eventMap)
  return @

Blaze.Template.prototype.helpersByInstance = (helpers) ->
  @helpers bindAllToTemplateInstance(helpers)
  return

Blaze.Template.prototype.eventsByInstance = (eventMap) ->
  @events bindAllToTemplateInstance(eventMap)
  return

Template2 = (template, config) ->
  if template instanceof Blaze.Template
  else
    if typeof template is 'string'
      template = Blaze.Template[template]
    else
      throw new Error 'template not found'
  template.onCreated ->
    @propsSchema config.propsSchema if config.propsSchema
    @modelSchema config.modelSchema if config.modelSchema
    @states config.states if config.states
    # @actions config.actions if config.actions
    return
  template.helpers bindAllToTemplateInstance(config.helpers) if config.helpers
  template.events bindAllToTemplateInstance(config.events) if config.events
  template.onCreated config.onCreated if config.onCreated
  template.onRendered config.onRendered if config.onRendered
  template.onRendered ->
    TemplateTwoWayBinding.rendered @
    return
  # XXX then Template.hello.onRendered ->
  template.onDestroyed config.onDestroyed if config.onDestroyed
