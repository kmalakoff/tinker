_ = require 'underscore'
Queue = require 'queue-async'
Async = require 'async'
inquirer = require 'inquirer'

Tinker = null
Config = require '../lib/config'
Module = require '../module'
repositoryServicesInit = require './repository_services'
Utils = require '../lib/utils'

TEMPLATES =
  introduction: """

    ****************
    Welcome to Tinker!
    ****************
    """

class TinkerInit
  @init: (options, callback) ->
    Tinker or= require '..'

    [options, callback] = [{}, options] if arguments.length is 1
    (return callback(new Error 'Tinker already initialized. Use --force to re-initialize')) if not options.force and (Config.get('package_types') or []).length

    console.log _.template(TEMPLATES.introduction)()

    queue = new Queue(1)
    queue.defer (callback) -> TinkerInit.configurePackageTypes(options, callback)
    queue.defer (callback) -> repositoryServicesInit(options, callback)
    queue.defer (callback) -> TinkerInit.configureModules(options, callback)
    queue.await callback

  @configurePackageTypes: (options, callback) ->
    package_types = Config.get('package_types') or []

    inquirer.prompt [
      {
        type: 'checkbox',
        name: 'package_types',
        message: "Choose the types of packages do you want to tinker with"
        choices: ({name: type, checked: type in package_types} for type in ['bower', 'npm'])
        validate: (answer) -> if answer.length < 1 then 'You must choose at least package type' else true
      }
    ],
    (answers) ->
      queue = new Queue(1)
      queue.defer (callback) -> Config.save(answers, callback)
      queue.defer (callback) -> Utils.load(options, callback) # reload
      queue.defer (callback) -> Tinker.install(options, callback)
      queue.await callback

  @configureModules: (options, callback) ->
    Module.findByGlob (options = Config.optionsSetPackageTypes(options)), (err, modules) ->
      return callback(err) if err
      return callback(new Error "No modules found for glob #{options.glob}") if modules.length is 0
      Async.eachSeries modules, ((module, callback) -> module.init options, callback), callback

module.exports = TinkerInit.init
