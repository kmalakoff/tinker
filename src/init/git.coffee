fs = require 'fs-extra'
path = require 'path-extra'
_ = require 'underscore'
inquirer = require 'inquirer'
Queue = require 'queue-async'

spawn = require '../lib/spawn'
Config = require '../config'

GLOBAL_IGNORE_FILES = ['.bower.json', '.npmignore']

TEMPLATES =
  introduction: """

    ****************
    You can store #{GLOBAL_IGNORE_FILES} in a global gitignore file.
    They are used internally by Bower and npm to recording installation information.
    See https://help.github.com/articles/ignoring-files for more information on using global gitignore files.

    """

class GitInit
  @init: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1

    gitignore = path.join(path.homedir(), '.gitignore_global')
    fs.readFile gitignore, 'utf8', (err, contents) ->
      contents or= ''
      added = (file for file in GLOBAL_IGNORE_FILES when contents.indexOf(file) < 0)
      return callback() if not added.length

      console.log _.template(TEMPLATES.introduction)(module)

      inquirer.prompt [{type: 'confirm', name: 'allow', message: "Do you want to add #{GLOBAL_IGNORE_FILES.join(' and ')} to #{gitignore}"}
      ], (answers) ->
        return callback() unless answers.allow

        queue = new Queue(1)
        queue.defer (callback) -> fs.ensureFile gitignore, callback
        queue.defer (callback) -> spawn "git config --global core.excludesfile #{gitignore}", callback # https://help.github.com/articles/ignoring-files
        queue.defer (callback) -> fs.writeFile gitignore, (contents += "\n#{added.join('\n')}"), 'utf8', (err) ->
          return callback(err) if err
          console.log "Added #{added.join(' ')} to #{gitignore}"
          callback()
        queue.await callback

module.exports = GitInit.init
