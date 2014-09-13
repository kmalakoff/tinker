_ = require 'underscore'
{File} = gutil = require 'gulp-util'
es = require 'event-stream'

module.exports = -> es.map (file, callback) -> file.pipe es.wait (err, contents) ->
  return callback(err) if err
  try
    callback(null, _.extend({contents: JSON.parse(contents)}, _.pick(file, 'cwd', 'base', 'path')))
  catch err
    gutil.log("JSON.parse failed #{file.path}. Error: #{err}"); return callback()
