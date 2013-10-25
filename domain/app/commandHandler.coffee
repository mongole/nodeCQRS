# here all the magic happens to handle a command:
#
# - pass it to aggregation root
# - store the event to storage
# - publishing event back to redis
redis = require("redis")
colors = require("./colors")
async = require("async")
items = require("./itemAggregate")
eventstore = require("eventstore")
storage = require("eventstore.redis")

# create a redis client - we will use this later to get new aggregateIds
db = redis.createClient()

# create a publisher which we use later to publish committed events back.
# just use another redis client and publish events to the _events channel_
publisher =
  evt: redis.createClient()
  publish: (evt) ->
    msg = JSON.stringify(evt, null, 4)
    console.log colors.green("\npublishing event to redis:")
    console.log msg
    publisher.evt.publish "events", msg


# for _EventSourcing_ we use [nodeEventStore](https://github.com/KABA-CCEAC/nodeEventStore):
#
# just create an instance and use one of the provided database providers
es = eventstore.createStore()

# configure the eventstore to use it and also inject the publisher implementation.
#
# finally start the eventstore instance so it will publish committed events to the provided
# publisher.
es.configure(->
  es.use db
  es.use publisher
  es.use storage.createStorage()
).start()

# for simplicity just map command names to event names. remove the command and change the message's id.
# in fact we just send back the received data with minor changes
map =
  mappings:
    createItem: "itemCreated"
    changeItem: "itemChanged"
    deleteItem: "itemDeleted"

  toEvent: (cmd) ->
    cmd.id = cmd.id + "_event_0"
    cmd.event = (if map.mappings[cmd.command] then map.mappings[cmd.command] else "unknown")
    delete cmd.command

    cmd

# the commandHandler does the heavy lifting:
commandHandler = handle: (cmd) ->
  cmdName = cmd.command
  id = cmd.payload.id

  # __don't do this at home:__ for simplicity we create the event already outside the aggregate - in a real system
  # you should create the event inside the aggregate (success or error), but as we only mirroring
  # the command back we take this shortcut.
  evt = map.toEvent(cmd)
  evt.time = new Date()

  # create an instance of itemAggregate
  # if the command provides no id (=createItem) - get a new id from redis db
  async.waterfall [(callback) ->
    unless id
      db.incr "nextItemId", (err, id) ->
        newId = "item:" + id
        console.log colors.cyan("create a new aggregate with id= " + newId)
        callback null, items.create(newId)

    else
      console.log colors.cyan("create existing aggregate with id= " + id)
      callback null, items.create(id)

    # load the eventstream (history) for the given id from eventstore
  , (item, callback ) ->
      console.log colors.cyan("load history for id= " + item.id)
      es.getEventStream item.id, (err, stream) ->
        callback null, item, stream


    # handle the command on aggregate
    #
    # - call loadFromHistory to apply all past events
    # - call the function matching the commandName
    # - add the uncommitted event to the eventstream and commit it
    #   the event will be published in eventstore after successful commit
  , (item, stream, callback) ->
      console.log colors.cyan("apply existing events " + stream.events.length)
      item.loadFromHistory stream.events
      console.log colors.magenta("apply new event " + evt.event + " to aggregate")
      item[cmdName] evt, (err, uncommitted) ->
        if err
          console.log colors.red(err)
        else
          stream.addEvent uncommitted[0]
          stream.commit()
  ]


exports.handle = commandHandler.handle