Queue = require 'queue-async'

Package = require '../package'
GitRepo = require '../git_repo'

module.exports = class Utils
  @load: (options, callback) ->
    queue = new Queue()
    queue.defer (callback) -> Package.load options, callback
    queue.defer (callback) -> GitRepo.load options, callback
    queue.await callback
