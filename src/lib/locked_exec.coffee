fs = require 'fs'
_ = require 'underscore'
lockfile = require 'lockfile'

LOCK_OPTIONS = {wait: 5*60*1000, retryWait: 10*1000}
LOCK_OPTIONS.stale = 3*LOCK_OPTIONS.wait
LOCK_OPTIONS.retries = 3*(LOCK_OPTIONS.wait/LOCK_OPTIONS.retryWait)

module.exports = (file_name, options, callback, fn) ->
  [options, callback, fn] = [{}, options, callback] if arguments.length is 3
  options = _.extend({}, LOCK_OPTIONS, options)

  lockfile.lock file_name, options, (err) =>
    return callback(err) if err

    fn (err) =>
      args = arguments
      lockfile.unlock file_name, (lock_err) =>
        return callback(err) if (err or= lock_err)
        callback.apply(callback, args)
