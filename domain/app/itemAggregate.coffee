# the itemAggregate is the aggregationRoot for a single item all commands concerning this 
# aggregate are handled inside this object.
colors = require("./colors")

# the itemAggregate has an internal state (id, text, destoyed)
Item = (id) ->
  @id = id
  @text = ""
  @_destroy = false
  @uncommittedEvents = []

Item:: =

# each __command__ is mapped to an aggregate function
# after validation the __event__ is applied to the object itself (changing
# the internal state of the aggregate)
#
# when all operations are done the callback will be called.
  createItem: (evt, callback) ->
    evt.payload.id = @id
    if evt.payload.text is ""
      callback new Error("It is not allowed to set an item text to empty string.")
    else
      @apply evt
      callback null, @uncommittedEvents

  changeItem: (evt, callback) ->
    if evt.payload.text is ""
      callback new Error("It is not allowed to set an item text to empty string.")
    else
      @apply evt
      callback null, @uncommittedEvents

  deleteItem: (evt, callback) ->
    @apply evt
    callback null, @uncommittedEvents


# apply the event to the aggregate calling the matching function
  apply: (evt) ->
    this["_" + evt.event] evt
    @uncommittedEvents.push evt  unless evt.fromHistory

  _itemCreated: (evt) ->
    @text = evt.payload.text

  _itemChanged: (evt) ->
    @text = evt.payload.text

  _itemDeleted: (evt) ->
    @_destroy = true


# function to reload an itemAggregate from it's past events by
# applying each event again
  loadFromHistory: (history) ->
    i = 0
    len = history.length

    while i < len
      e = history[i].payload
      e.fromHistory = true
      @apply e
      i++


# export the modules function to create a new itemAggregate
exports.create = (id) ->
  new Item(id)