_ = require 'underscore'
Queue = require 'queue-async'
Async = require 'async'
inquirer = require 'inquirer'

Config = require '../lib/config'
Module = require '../module'

TEMPLATES =
  introduction: """

    ****************
    Welcome to Tinker!
    ****************
    """

class TinkerInit
  @init: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    console.log _.template(TEMPLATES.introduction)()

    queue = new Queue(1)
    queue.defer (callback) -> TinkerInit.configurePackageTypes(options, callback)
    queue.defer (callback) -> TinkerInit.configureModules(options, callback)
    queue.await callback

  @configurePackageTypes: (options, callback) ->
    package_types = Config.get('package_types') or []
    (console.log 'Package type already selected'; return callback()) if not options.force and package_types.length

    inquirer.prompt [
      {
        type: 'checkbox',
        name: 'package_types',
        message: "Choose the types of packages do you want to tinker with"
        choices: ({name: type, checked: type in package_types} for type in ['bower', 'npm'])
        validate: (answer) -> if answer.length < 1 then 'You must choose at least package type' else true
      }
    ],
    (answers) -> Config.save answers, callback

  @configureModules: (options, callback) ->
    types = _.object(Config.get('package_types'), (true for type in Config.get('package_types')))
    (require '..').install (options = _.defaults(types, options)), (err) ->
      return callback(err) if err

      Module.findByGlob options, (err, modules) ->
        return callback(err) if err
        return callback(new Error "No modules found for glob #{options.glob}") if modules.length is 0
        Async.eachSeries modules, ((module, callback) -> module.init options, callback), callback

module.exports = TinkerInit.init
