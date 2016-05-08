TemplateTwoWayBinding.getter = (variable) ->
  @state[variable]

TemplateTwoWayBinding.setter = (variable, value) ->
  @validateOne.call @, variable, value
  @state[variable] = value
  return

# TemplateTwoWayBinding.operator = (variable, operator, params) ->
#   console.log 'operator', variable, operator, params
#   return if operator is 'omit'

Blaze.TemplateInstance.prototype.modelSchema = (schema, validationContext) ->
  if @__modelSchema
    throw new Error 'allowed only one call of modelSchema'
  if not schema
    throw new Error 'property schema required'
  @__modelSchema = schema.schema()
  if validationContext
    if not validationContext.validate or not validationContext.validateOne
      throw new Error 'invalid interface of validationContext'
    @validationContext = validationContext
  else if schema instanceof SimpleSchema
    @validationContext = schema.newContext()
  else
    throw new Error 'property validationContext required'
  states = {}
  for variable, field of @__modelSchema
    states[variable] = field.defaultValue or ''
  states['errorMessages'] = []
  @states(states)
  return @

Blaze.TemplateInstance.prototype.modelMap = ->
  if not @__modelSchema
    error = new Error 'Model Schema Required'
    error.name = 'ModelSchemaRequired'
    throw error
  TemplateTwoWayBinding.rendered @
  return @

Blaze.TemplateInstance.prototype.modelDoc = (doc) ->
  if not @__modelSchema
    error = new Error 'Model Schema Required'
    error.name = 'ModelSchemaRequired'
    throw error
  @validationContext.resetValidation()
  @state.errorMessages = []
  if doc
    for variable of @__modelSchema
      @state[variable] = if doc[variable] == 'undefined' then '' else doc[variable]
  else
    for variable, field of @__modelSchema
      @state[variable] = field.defaultValue or ''
  return @

Blaze.TemplateInstance.prototype.validateOne = (variable, value) ->
  doc = {}
  doc[variable] = value
  @validationContext.validateOne(doc, variable)
  @state.errorMessages = _.map @validationContext.getErrorObject().invalidKeys, (error) ->
    return " #{error.message}"
  return @

Blaze.TemplateInstance.prototype.viewDoc = (callback) ->
  if not @__modelSchema
    error = new Error 'Model Schema Required'
    error.name = 'ModelSchemaRequired'
    throw error
  error = null
  doc = {}
  for variable of @__modelSchema
    doc[variable] = @state[variable]
  if @validationContext.validate(doc)
    @state.errorMessages = []
  else
    @state.errorMessages = _.map @validationContext.getErrorObject().invalidKeys, (error) ->
      return " #{error.message}"
    error = new Error 'Validation Error'
    error.name = 'ValidationError'
    doc = null
  callback.call @, error, doc
  return @

# old = Template.prototype.constructView
# Template.prototype.constructView = ->
#   console.log 'hack', @
#   old.apply @, arguments
