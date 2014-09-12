_ = require 'underscore'

class Config extends (require './disk_model')
  url: './.tinker'
  defaults: {package_types: [], modules: []}

  configByModule: (module, config) ->
    if arguments.length is 1
      return _.findWhere(@get('modules'), {path: module.get('path')})
    else
      modules.splice(_.indexOf(modules, previous_config), 1) if previous_config = _.findWhere(modules = @get('modules'), {path: module.get('path')})
      modules.push(config)
      modules.sort (a, b) -> a.name.localeCompare(b.name)
      return @

module.exports = new Config()
