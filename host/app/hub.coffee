# the hub encapsulates functionality to send or receive messages from redis.
redis = require("redis")
colors = require("./colors")
map = require("./msgmap")


cmd = redis.createClient()
evt = redis.createClient()
subscriptions = []

# send commands to redis __commands channel__
exports.emit = (commandName, sender, message) ->
  data = map.to(commandName, sender, message)
  console.log colors.blue("\nhub -- publishing command " + commandName + " to redis:")
  console.log data.blue
  cmd.publish "commands", data


# store subscriptions for a channel (mostly __events__) in a array
exports.on = (channel, callback) ->
  subscriptions.push
    channel: channel
    callback: callback

  console.log colors.blue("hub -- subscribers: " + subscriptions.length)


# listen to events from redis and call each callback from subscribers
evt.on "message", (channel, message) ->
  data = map.from(channel, message)
  console.log colors.green("\nhub -- received event " + data.event + " from redis:")
  console.log message.green
  subscriptions.forEach (subscriber) ->
    console.log colors.green("should subscriber " + subscriber + " be notified?")
    subscriber.callback data  if channel is subscriber.channel



# subscribe to __events channel__
evt.subscribe "events"