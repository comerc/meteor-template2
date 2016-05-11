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

propsCleanConfiguration = {}

# Init props
Blaze.TemplateInstance.prototype.propsSchema = (schema) ->
  # Setup validated reactive props passed from the outside
  if not (schema and schema.validate and schema.clean)
    throw propertyValidatorRequired()
  @__propsSchema = schema
  if not @props
    @props = new ReactiveObject
    helpers = {}
    # for usage as {{propsBy "variable-name"}}
    helpers.propsBy = (variable) ->
      Template.instance().props[variable]
    helpers.props = ->
      Template.instance().props
    @view.template.helpers helpers
    @autorun =>
      currentData = Template.currentData() or {}
      @__propsSchema.clean currentData, propsCleanConfiguration
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
    # for usage as {{stateBy "variable-name"}}
    helpers.stateBy = (variable) ->
      Template.instance().state[variable]
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

Template2.setPropsCleanConfiguration = (config) ->
  propsCleanConfiguration = config
