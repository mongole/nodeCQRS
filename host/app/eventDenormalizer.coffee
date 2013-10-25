# the eventdenormalizer handles events and updates the viewmodel.
store = require("./storage")
async = require("async")
colors = require("./colors")

# pass events to matching functions to:
#
# - create an item
# - change an item
# - delete an item
eventHandler =
  handle: (evt) ->
    eventHandler[evt.event] evt

  itemCreated: (evt) ->
    store.save
      id: evt.payload.id
      text: evt.payload.text
    , (err) ->

  itemChanged: (evt) ->
    store.load evt.payload.id, (err, item) ->
      item.text = evt.payload.text
      store.save item, (err) ->

  itemDeleted: (evt) ->
    store.del evt.payload.id, (err) ->


exports.handle = eventHandler.handle