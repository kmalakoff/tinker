_ = require 'underscore'

Package = null

class Config extends (require './disk_model')
  url: './.tinker'
  defaults: {repository_services: [], package_types: [], modules: []}

  configByModule: (module, config) ->
    if arguments.length is 1
      return _.findWhere(@get('modules'), {path: module.get('path')})
    else
      modules.splice(_.indexOf(modules, previous_config), 1) if previous_config = _.findWhere(modules = @get('modules'), {path: module.get('path')})
      modules.push(config)
      modules.sort (a, b) -> a.name.localeCompare(b.name)
      return @

  optionsSetPackageTypes: (options) ->
    Package or= require '../package'; package_types = @get('package_types')
    _.defaults(_.object(Package.TYPES, ((type in package_types) for type in Package.TYPES)), options)

module.exports = new Config()
