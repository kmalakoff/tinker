_ = require 'underscore'
Queue = require 'queue-async'
Async = require 'async'
inquirer = require 'inquirer'

Config = require '../config'
Package = require '../package'
Module = require '../module'
TinkerUtils = require '../lib/utils'

TEMPLATES =
  introduction: """

    ****************
    Welcome to Tinker!
    ****************
    """

  install: """

    ****************
    """

class TinkerInit
  @init: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1

    console.log _.template(TEMPLATES.introduction)()

    queue = new Queue(1)
    queue.defer (callback) -> TinkerInit.configurePackageTypes(options, callback)
    queue.defer (callback) -> (require './servers')(options, callback)
    queue.defer (callback) -> (require './git')(options, callback)
    queue.defer (callback) ->
      console.log _.template(TEMPLATES.install)()
      inquirer.prompt [{type: 'confirm', name: 'allow', message: "Do you want to install #{(Config.get('types') or []).join(' and ')} packages to start tinkering?"}
      ], (answers) ->
        return callback() unless answers.allow
        Package.cursor().include('modules').toModels (err, packages) ->
          return callback(err) if err
          Async.eachSeries packages, ((pkg, callback) -> pkg.install(options, callback)), callback
    queue.defer (callback) -> TinkerUtils.load(options, callback) # reload
    queue.defer (callback) -> TinkerInit.configureModules(options, callback)
    queue.await callback

  @configurePackageTypes: (options, callback) ->
    types = Config.get('types') or []

    inquirer.prompt [
      {
        type: 'checkbox',
        name: 'types',
        message: "Choose the types of packages do you want to tinker with"
        choices: ({name: type, checked: type in types} for type in ['bower', 'npm'])
        validate: (answer) -> if answer.length < 1 then 'You must choose at least package type' else true
      }
    ],
    (answers) -> Config.save(answers, callback)

  @configureModules: (options, callback) ->
    options = Config.optionsSetPackageTypes(options)
    Module.eachSeriesByGlob options, ((module, callback) -> module.init options, callback), -> callback()

module.exports = TinkerInit.init
