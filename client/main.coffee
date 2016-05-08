{ Template } = require 'meteor/templating'

require './main.jade'

Template.demo.onCreated ->
  @propsSchema new SimpleSchema(test: type: String)
  @modelSchema Nodes.simpleSchema()
  @states
    nodeId: false
    submitMessage: ''
  @helpers
    nodes: ->
      Nodes.find()
  @events
    'click a.node': (e) ->
      e.preventDefault()
      @state.nodeId = $(e.target).data('node-id') or false
    'submit form': (e) ->
      e.preventDefault()
      @viewDoc (error, doc) ->
        return if error
        # save data
        if @state.nodeId
          Nodes.update @state.nodeId, $set: doc,
            => @state.submitMessage = 'updated'
        else
          @state.nodeId = Nodes.insert doc,
            => @state.submitMessage = 'inserted'

# old school of declaration with context of Template.instance()
Template.demo.eventsByInstance
  'click #reset': (e) ->
    e.preventDefault()
    @modelDoc false
    @state.submitMessage = ''

Template.demo.onRendered ->
  @modelMap() # magic here :)
  @autorun =>
    # console.log 'autorun'
    if @state.nodeId
      @modelDoc Nodes.findOne @state.nodeId
    else
      @modelDoc false
    @state.submitMessage = ''
