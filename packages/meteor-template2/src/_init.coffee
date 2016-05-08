Template2 = {}

Blaze.Template.prototype.init = (config) ->
  @onCreated ->
    @propsSchema config.propsSchema if config.propsSchema
    @modelSchema config.modelSchema if config.modelSchema
    @states config.states if config.states
    @events config.events if config.events
    @helpers config.helpers if config.helpers
    @actions config.actions if config.actions
    return
  @onRendered ->
    if @__modelSchema # we may use Template2 wo model
      TemplateTwoWayBinding.rendered @
    return
