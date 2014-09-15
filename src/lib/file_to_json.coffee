fs = require 'fs'
_ = require 'underscore'
{File} = require 'gulp-util'
es = require 'event-stream'

module.exports = (file, callback) ->
  if _.isString(file)
    file = new File({path: file, contents: source = fs.createReadStream(file)})
    callback = _.once(callback); source.on 'error', -> "Failed to load: #{file.path}"; return callback()

  file.pipe es.wait (err, contents) ->
    try callback(null, JSON.parse(contents))
    catch err then (console.log "Failed to parse: #{file.path}. Contents: #{contents}. Error: #{err}"; return callback())
