fs = require 'fs'
_ = require 'underscore'
{File} = require 'gulp-util'
es = require 'event-stream'

module.exports = (file, callback) ->
  fs.exists file.path or file, (exists) ->
    ("Failed to load: #{file.path}"; return callback()) unless exists
    file = new File({path: file, contents: fs.createReadStream(file)}) if _.isString(file)
    file.pipe es.wait (err, contents) ->
      try callback(null, JSON.parse(contents))
      catch err then (console.log "Failed to parse: #{file.path}. Contents: #{contents}. Error: #{err}"; return callback())
