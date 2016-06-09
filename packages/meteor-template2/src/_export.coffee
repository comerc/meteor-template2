Template2Config = {}

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
    @actions config.actions if config.actions
    # XXX helpers and events init once
    return if template._isTemplate2Init
    template._isTemplate2Init = true
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
