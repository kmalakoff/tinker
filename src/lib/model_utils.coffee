_ = require 'underscore'
{File} = require 'gulp-util'
es = require 'event-stream'

module.exports = class ModelUtils
  @findOrCreateFn: (type, setFile) ->
    __findOrCreate = type.findOrCreate
    return fn = (info, callback) ->
      return fn(new File({path: info}), callback) if _.isString(info) and arguments.length is 2 # a path
      return __findOrCreate.apply(type, arguments) unless info.pipe # not a file

      # a file
      __findOrCreate.call type, _.pick((file = info), 'path'), (err, model) ->
        return callback(err) if err
        callback = _.once(callback)
        file.pipe es.wait (err, contents) ->
          (console.log "Failed to load: #{file.path}. Error: #{err}"; return callback()) if err
          try setFile.call(model, _.extend({contents: JSON.parse(contents.toString())}, _.pick(file, 'path'))); model.save(callback)
          catch err then (console.log "Failed to parse: #{file.path}. Contents: #{contents}. Error: #{err}"; return callback())
