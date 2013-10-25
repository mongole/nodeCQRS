# the message map just enriches or reduces the commands/events
# received from browser / redis with additional
# information like sender and timestamp
map =
  to:
    channelNeedsCustom: (channel, sender, message) ->
      msg =
        id: message.id
        command: message.command
        sender: sender
        payload: message.payload

      JSON.stringify msg, null, 4

    default: (channel, sender, message) ->
      msg =
        id: message.id
        command: message.command
        time: new Date()
        sender: sender
        payload: message.payload

      JSON.stringify msg, null, 4

  from:
    channelNeedsCustom: (channel, message) ->
      msg = JSON.parse(message)
      data =
        id: msg.id
        event: msg.event
        payload: msg.payload

      data

    default: (channel, message) ->
      msg = JSON.parse(message)
      data =
        id: msg.id
        event: msg.event
        payload: msg.payload

      data

exports.to = (channel, sender, message) ->
  if map.to[channel]
    map.to[channel] channel, sender, message
  else
    map.to["default"] channel, sender, message

exports.from = (channel, message) ->
  if map.from[channel]
    map.from[channel] channel, message
  else
    map.from["default"] channel, message