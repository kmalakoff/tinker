_ = require 'underscore'
es = require 'event-stream'
File = require 'vinyl'

module.exports = (file, callback) -> file.pipe es.wait (err, contents) ->
  return callback(err) if err
  try
    callback(null, _.extend({contents: JSON.parse(contents)}, _.pick(file, 'cwd', 'base', 'path')))
  catch err
    return callback(err)
