fs = require 'fs'
path = require 'path'
_ = require 'underscore'

module.exports = class FSModel extends (require 'backbone').Model
  load: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    @clear().set(_.result(@, 'defaults'))
    fs.readFile @file_path = @optionsToFilePath(options), 'utf8', (err, contents) =>
      return callback(null, @) if err
      try callback(null, @set(JSON.parse(contents))) catch err then callback(new Error "#{@file_path}: #{err.toString()}")

  save: (attributes, callback) ->
    return callback(new Error 'FSModel: not file_path for save. Load using load function or set file_path') unless @file_path

    [attributes, callback] = [{}, attributes] if arguments.length is 1
    @set(attributes)
    fs.writeFile @file_path, JSON.stringify(@toJSON(), null, 2), 'utf8', callback

  optionsToFilePath: (options) ->
    url = _.result(@, 'url')
    return if options.directory then path.join(process.cwd(), options.directory, url) else path.join(process.cwd(), url)
