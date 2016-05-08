# { Random } = require 'meteor/random'

@Nodes = new (Mongo.Collection)('nodes')

@NodeSchema = new SimpleSchema
  fieldHead:
    type: String
    label: 'My Head'
    max: 3
    # defaultValue: '111'
  fieldBody:
    type: String
    label: 'My Body'
    min: 3
    defaultValue: '777'

Nodes.attachSchema(NodeSchema)

# data = fieldHead: '123', fieldBody: '321'
# id = Random.id()
# console.log data
#
# Nodes.update id, $set: data,
#   upsert: true
# console.log Nodes.find().count()
