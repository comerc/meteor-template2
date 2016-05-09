{ Template } = require 'meteor/templating'

require './main.jade'

Template2.mixin Template.hello,
  propsSchema: new SimpleSchema(test: type: String)
  modelSchema: Nodes.simpleSchema()
  states:
    nodeId: false
    submitMessage: ''
  helpers:
    nodes: ->
      Nodes.find()
  events:
    'click a.node': (e) ->
      e.preventDefault()
      @state.nodeId = $(e.target).data('node-id') or false
    'submit form': (e) ->
      e.preventDefault()
      @viewDoc (error, doc) ->
        return console.log error.message if error
        # save data
        if @state.nodeId
          Nodes.update @state.nodeId, $set: doc,
            => @state.submitMessage = 'updated'
        else
          @state.nodeId = Nodes.insert doc,
            => @state.submitMessage = 'inserted'

Template.hello.onRendered ->
  @autorun =>
    if @state.nodeId
      @modelDoc Nodes.findOne @state.nodeId
    else
      @modelDoc false
    @state.submitMessage = ''

Template.hello.eventsByInstance
  'click #reset': (e) ->
    e.preventDefault()
    @modelDoc false
    @state.submitMessage = ''
