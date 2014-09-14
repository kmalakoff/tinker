fs = require 'fs'
_ = require 'underscore'
{File} = require 'gulp-util'

module.exports = class ModelUtils
  @findOrCreateByFileOverloadFn: (type, setFile) ->
    __findOrCreate = type.findOrCreate
    return fn = (info, callback) ->
      info = new File({file: info, contents: fs.createReadStream(info)}) if _.isString(info) and (arguments.length is 2) # a path
      return __findOrCreate.apply(type, arguments) unless info.pipe

      __findOrCreate.call type, _.pick((file = info), 'path'), (err, model) ->
        if err then callback(err) else setFile.call(model, file, callback)
