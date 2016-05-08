# for custom override
Blaze.TemplateInstance.prototype.validateOne = (doc, variable) ->
  result = @validationContext.validateOne(doc, variable)
  @state.errorMessages = _.map @validationContext.getErrorObject().invalidKeys, (error) ->
    return " #{error.message}"
  return result

# for custom override
Blaze.TemplateInstance.prototype.validate = (doc) ->
  result = @validationContext.validate(doc)
  if result
    @state.errorMessages = []
  else
    @state.errorMessages = _.map @validationContext.getErrorObject().invalidKeys, (error) ->
      return " #{error.message}"
  return result

checkModelSchema = (templateInstance) ->
  if not templateInstance.__modelSchema
    error = new Error 'Model Schema Required'
    error.name = 'ModelSchemaRequired'
    throw error

Blaze.TemplateInstance.prototype.modelSchema = (schema, validationContext) ->
  if not schema
    throw new Error 'property schema required'
  @__modelSchema = schema
  if validationContext
    @validationContext = validationContext
  else
    @validationContext = schema.newContext()
  states = {}
  for variable, field of @__modelSchema.schema()
    states[variable] = field.defaultValue or ''
  states['errorMessages'] = []
  @states(states)
  return @

Blaze.TemplateInstance.prototype.modelDoc = (doc) ->
  checkModelSchema @
  @validationContext.resetValidation()
  @state.errorMessages = []
  if doc
    for variable of @__modelSchema.schema()
      @state[variable] = if doc[variable] == 'undefined' then '' else doc[variable]
  else
    for variable, field of @__modelSchema.schema()
      @state[variable] = field.defaultValue or ''
  return @

modelCleanConfiguration = {}

Blaze.TemplateInstance.prototype.viewDoc = (callback) ->
  checkModelSchema @
  error = null
  doc = {}
  for variable of @__modelSchema.schema()
    doc[variable] = @state[variable]
  @__modelSchema.clean(doc, modelCleanConfiguration)
  if not @validate(doc)
    error = new Error 'Validation Error'
    error.name = 'ValidationError'
    doc = null
  callback.call @, error, doc
  return @

TemplateTwoWayBinding.getter = (variable) ->
  return @state[variable]

TemplateTwoWayBinding.setter = (variable, value) ->
  doc = {}
  doc[variable] = value
  @validateOne.call @, doc, variable
  @state[variable] = value
  return

oldConstructView = Template.prototype.constructView

Template.prototype.constructView = ->
  @onRendered ->
    if @__modelSchema # we may use Template2 wo model
      TemplateTwoWayBinding.rendered @
    return
  return oldConstructView.apply @, arguments

Template2.setModelCleanConfiguration = (config) ->
  modelCleanConfiguration = config
