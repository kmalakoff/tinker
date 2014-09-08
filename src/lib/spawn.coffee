{spawn} = require 'child_process'
_ = require 'underscore'

module.exports = (cmd, options={}, callback) ->
  [options, callback] = [{}, options] if arguments.length is 2
  done = _.after(callback = _.once(callback), 3) # make sure all processes end or any error is handled

  cmd_parts = cmd.split(' ')
  args = [cmd_parts.shift(), cmd_parts]
  options = _.clone(options)
  options.env = if options.env then _.extend({}, options.env, process.env) else process.env
  args.push(options)

  child = spawn.apply(null, args)
  child.stderr.on 'error', callback
  child.stderr.on 'data', (chunk) => process.stdout.write(chunk.toString())
  child.stderr.on 'end', done
  child.stdout.on 'error', callback
  child.stdout.on 'data', (chunk) => process.stdout.write(chunk.toString())
  child.stdout.on 'end', done
  child.on 'error', callback
  child.on 'exit', -> done()
