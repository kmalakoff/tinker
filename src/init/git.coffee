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

GLOBAL_IGNORE_FILES = ['.bower.json', '.npmignore']

class GitInit
  @init: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1

    gitignore = path.join(pwuid().dir, '.gitignore_global')
    console.log _.template(TEMPLATES.introduction)(module)

    inquirer.prompt [
     {
        type: 'confirm',
        name: 'allow',
        message: "Do you want to add #{GLOBAL_IGNORE_FILES.join(' and ')} to #{gitignore}.\nSee https://help.github.com/articles/ignoring-files for more information",
      }
    ], (answers) ->
      return callback() unless answers.allow

      queue = new Queue(1)
      queue.defer (callback) -> fs.ensureFile gitignore, callback
      queue.defer (callback) -> spawn "git config --global core.excludesfile #{gitignore}", callback # https://help.github.com/articles/ignoring-files
      queue.defer (callback) -> fs.readFile gitignore, 'utf8', (err, contents) ->
        return callback(err) if err

        added = (file for file in GLOBAL_IGNORE_FILES when contents.indexOf(file) < 0)
        (console.log "No files added to #{gitignore}"; return callback()) unless added.length
        fs.writeFile gitignore, (contents += "\n#{added.join('\n')}"), 'utf8', (err) ->
          return callback(err) if err
          console.log "Added #{added.join(' ')} to #{gitignore}"
          callback()

      queue.await callback

module.exports = GitInit.init
