Template2 = {}

Template2.mixin = (template, config) ->
  if template instanceof Blaze.Template
  else
    if typeof template is 'string'
      template = Blaze.Template[template]
    else
      template = undefined
  template.onCreated ->
    @propsSchema config.propsSchema if config.propsSchema
    @modelSchema config.modelSchema if config.modelSchema
    @states config.states if config.states
    @events config.events if config.events
    @helpers config.helpers if config.helpers
    @actions config.actions if config.actions
    return
  template.onCreated config.onCreated if config.onCreated
  template.onRendered ->
    TemplateTwoWayBinding.rendered @
    return
  template.onRendered config.onRendered if config.onRendered
  template.onDestroyed config.onDestroyed if config.onDestroyed
