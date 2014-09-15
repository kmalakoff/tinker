_ = require 'underscore'
inquirer = require 'inquirer'

Config = require '../config'
PackageUtils = require '../lib/package_utils'
RepoUtils = require '../lib/repo_utils'
RepoURL = require '../lib/repo_url'

TEMPLATES =
  introduction: """

    ****************
    """

class ModuleInit
  @init: (module, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2

    console.log _.template(TEMPLATES.introduction)(module)
    ModuleInit.selectRepository(module, options, callback)

  @selectRepository: (module, options, callback) ->
    module.repositories options, (err, repositories) ->
      return callback(err) if err

      inquirer.prompt [
        {
          type: 'list',
          name: 'url',
          message: "Which repository url do you want to use for #{module.get('name')} (#{module.relativeDirectory(options)})?"
          choices: repositories.concat(['Skip', 'Other'])
        }
      ], (answers) ->
        switch (url = answers.url).toLowerCase()
          when '' then return ModuleInit.selectRepository(module, options, callback)
          when 'skip' then return callback()
          when 'other' then return ModuleInit.enterRepository(module, options, callback)
          else Config.saveModuleConfig(module.set({url: url}), callback)

  @enterRepository: (module, options, callback) ->
    inquirer.prompt [
     {
        type: 'input',
        name: 'url',
        message: 'Enter a repository url or type skip or leave empty to start again',
        validate: (value) ->
          return true if !value or (value.toLowerCase() is 'skip') or RepoURL.isValid(value)
          'Please enter a valid repository url'
      }
    ], (answers) ->
      switch (url = answers.url).toLowerCase()
        when '' then return ModuleInit.selectRepository(module, options, callback)
        when 'skip' then return callback()
        else Config.saveModuleConfig(module.set({url: url}), callback)

module.exports = ModuleInit.init
