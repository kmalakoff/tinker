_ = require 'underscore'

PROPERTIES = ['name', 'path', 'url', 'package_url']

module.exports = class Module
  constructor: (options) ->
    @[key] = value for key, value of _.pick(options, PROPERTIES)
    throw new Error "Module missing #{key}" for key in PROPERTIES when not @hasOwnProperty(key)
