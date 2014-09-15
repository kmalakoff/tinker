fs = require 'fs'
_ = require 'underscore'
{File} = require 'gulp-util'

module.exports = class ModelUtils
  @findOrCreateByFileOverloadFn: (type, setFile) ->
    __findOrCreate = type.findOrCreate
    return (info, callback) ->
      return __findOrCreate.apply(type, arguments) if not (info.pipe or _.isString(info) and (arguments.length is 2))
      __findOrCreate.call type, {path: info.path or info}, (err, model) ->
        if err then callback(err) else setFile.call(model, info, callback)
