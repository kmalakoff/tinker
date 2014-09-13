_ = require 'underscore'
inquirer = require 'inquirer'
validator = require 'validator'

Config = require '../lib/config'
PackageUtils = require '../lib/package_utils'
RepoUtils = require '../lib/repo_utils'

TEMPLATES =
  introduction: """

    """

class RepositoryServicesInit
  @init: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1

    console.log _.template(TEMPLATES.introduction)(module)
    console.log "Known repository services: #{repository_services.join(', ')}" if (repository_services = Config.get('repository_services') or []).length
    RepositoryServicesInit.enterRepositoryService(options, callback)

  @enterRepositoryService: (options, callback) ->
    inquirer.prompt [
     {
        type: 'input',
        name: 'url',
        message: 'Enter a repository service url for fork discovery (leave empty to skip)',
        validate: (value) ->
          return true if !value or (value.toLowerCase() is 'skip') or validator.isURL(value)
          'Please enter a valid repository service url'
      }
    ], (answers) ->
      switch (url = answers.url).toLowerCase()
        when ''
          console.log "Known repository services: #{repository_services.join(', ')}" if (repository_services = Config.get('repository_services') or []).length
          return callback()
        else
          console.log "Added #{url}"
          Config.save {repository_services: _.uniq((Config.get('repository_services') or []).concat([url]))}, (err) ->
            return callback(err) if err
            RepositoryServicesInit.enterRepositoryService(options, callback)

module.exports = RepositoryServicesInit.init
