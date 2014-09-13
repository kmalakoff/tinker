fs = require 'fs-extra'
path = require 'path'
_ = require 'underscore'
inquirer = require 'inquirer'
pwuid = require 'pwuid'
Queue = require 'queue-async'

spawn = require '../lib/spawn'
Config = require '../config'

TEMPLATES =
  introduction: """

    ****************
    """

GLOBAL_IGNORE_FILES =
  bower: ['.bower.json']
  npm: ['.npmignore']

class GitInit
  @init: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1

    console.log _.template(TEMPLATES.introduction)(module)
    queue = new Queue(1)
    for key, files of GLOBAL_IGNORE_FILES
      for file in files
        do (file) -> queue.defer (callback) -> GitInit.addGlobalGitignore(file, callback)
    queue.await callback

  @addGlobalGitignore: (file, callback) ->
    gitignore = path.join(pwuid().dir, '.gitignore_global')

    inquirer.prompt [
     {
        type: 'confirm',
        name: 'allow',
        message: "Add #{file} to #{gitignore}?",
      }
    ], (answers) ->
      return callback() unless answers.allow

      queue = new Queue(1)
      queue.defer (callback) -> fs.ensureFile gitignore, callback
      queue.defer (callback) -> spawn "git config --global core.excludesfile #{gitignore}", callback # https://help.github.com/articles/ignoring-files
      queue.defer (callback) -> fs.readFile gitignore, 'utf8', (err, contents) ->
        return callback(err) if err or contents.indexOf(file) >= 0
        fs.writeFile gitignore, (contents += "\n#{file}"), 'utf8', callback
      queue.await callback

module.exports = GitInit.init
