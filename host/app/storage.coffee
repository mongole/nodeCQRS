# simple storage for loading, changing and deleting items
redis = require("redis")
async = require("async")
colors = require("./colors")


db = redis.createClient()
store =
  load: (id, callback) ->
    db.get "readmodel:" + id, (err, data) ->
      callback err  if err
      callback null, JSON.parse(data)


  loadAll: (callback) ->
    db.smembers "readmodel:items", (err, keys) ->
      callback err  if err
      async.map keys, store.load, (err, items) ->
        callback err  if err
        callback null, items



  save: (item, callback) ->
    db.sismember "readmodel:items", item.id, (err, exists) ->
      callback err  if err
      db.sadd "readmodel:items", item.id  unless exists
      db.set "readmodel:" + item.id, JSON.stringify(item)
      callback null


  del: (id, callback) ->
    db.srem "readmodel:items", id, (err) ->
      callback err  if err
      db.del id, (err) ->
        callback err  if err
        callback null



module.exports = store