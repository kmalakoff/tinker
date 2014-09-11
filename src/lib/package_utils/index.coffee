path = require 'path'

module.exports = class Utils
  @call: (pkg, name, args) -> Utils.apply.apply(Utils, [pkg, name].concat(Array::slice.call(args)))

  @apply: (_args_) ->
    args = Array::slice.call(arguments); pkg = args[0]; name = args[1]; callback = args[args.length-1]
    return callback(new Error "Package missing type for calling #{name}") unless type = pkg.get('type')
    try
      _Utils = require "./#{type}"
      return callback(new Error "Utils function not found for calling #{name} for type: #{type}") unless fn = _Utils[name]
      fn.apply(fn, [pkg].concat(args.splice(2)))
    catch err then return callback(err)

  @root: (pkg) -> path.dirname(pkg.get('path'))
  @cwd: (pkg) -> {cwd: Utils.root(pkg)}
