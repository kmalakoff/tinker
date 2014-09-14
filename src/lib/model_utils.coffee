_ = require 'underscore'
{File} = require 'gulp-util'
es = require 'event-stream'

module.exports = class ModelUtils
  @findOrCreateByFileFn: (type, setFile) -> fn = (info, callback) ->
    return fn(new File({path: info}), callback) if _.isString(info) and arguments.length is 2 # a path
    return type.findOrCreate.apply(type, arguments) unless info.pipe # not a file

    # a file
    type.findOrCreate _.pick((file = info), 'path'), (err, model) ->
      return callback(err) if err
      callback = _.once(callback)
      file.pipe es.wait (err, contents) ->
        (console.log "Failed to load: #{file.path}. Error: #{err}"; return callback()) if err
        try setFile.call(model, _.extend({contents: JSON.parse(contents.toString())}, _.pick(file, 'path'))); model.save(callback)
        catch err then (console.log "Failed to parse: #{file.path}. Contents: #{contents}. Error: #{err}"; return callback())
