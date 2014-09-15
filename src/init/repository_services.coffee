_ = require 'underscore'
inquirer = require 'inquirer'
validator = require 'validator'

Config = require '../config'
PackageUtils = require '../lib/package_utils'
RepoUtils = require '../lib/repo_utils'

TEMPLATES =
  introduction: """

    ****************
    You can register your favorite repository service to find your repositories and forks. For example: https://github.com/yourname
    """

class RepositoryServicesInit
  @init: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1

    console.log _.template(TEMPLATES.introduction)(module)
    console.log "Currently registered repository services: #{repository_services.join(', ')}" if (repository_services = Config.get('repository_services') or []).length
    console.log ''
    RepositoryServicesInit.enterRepositoryService(options, repository_services, callback)

  @enterRepositoryService: (options, initial_repository_services, callback) ->
    inquirer.prompt [
     {
        type: 'input',name: 'url', message: 'Enter a repository service (leave empy to skip)',
        validate: (value) ->
          return true if !value or (value.toLowerCase() is 'skip') or validator.isURL(value)
          'Please enter a valid repository service url'
      }
    ], (answers) ->
      switch (url = answers.url).toLowerCase()
        when ''
          if (repository_services = Config.get('repository_services') or []).length
            console.log "Known repository services: #{repository_services.join(', ')}" if _.difference(initial_repository_services, repository_services).length
          return callback()
        else
          console.log "Added #{url}"
          Config.save {repository_services: _.uniq((Config.get('repository_services') or []).concat([url]))}, (err) ->
            return callback(err) if err
            RepositoryServicesInit.enterRepositoryService(options, initial_repository_services, callback)

module.exports = RepositoryServicesInit.init
