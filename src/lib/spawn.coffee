{spawn} = require 'child_process'
_ = require 'underscore'

module.exports = (cmd, options={}, callback) ->
  [options, callback] = [{}, options] if arguments.length is 2

  done = callback
  was_called = false; call_count = 3
  callback = (err) ->
    return if was_called
    (was_called = true; return done(err)) if err
    return if --call_count > 0
    was_called = true; return done()

  cmd_parts = cmd.split(' ')
  args = [cmd_parts.shift(), cmd_parts]
  options = _.clone(options)
  options.env = if options.env then _.extend({}, options.env, process.env) else process.env
  args.push(options)

  child = spawn.apply(null, args)
  child.stderr.on 'error', callback
  child.stderr.on 'data', (chunk) => process.stdout.write(chunk.toString())
  child.stderr.on 'end', callback
  child.stdout.on 'error', callback
  child.stdout.on 'data', (chunk) => process.stdout.write(chunk.toString())
  child.stdout.on 'end', callback
  child.on 'error', callback
  child.on 'exit', -> callback()
