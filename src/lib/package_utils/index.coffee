path = require 'path'

module.exports = class Utils
  @call: (pkg, name, args) ->
    args = Array::slice.call(args); args.unshift(pkg); callback = args[args.length-1]
    return callback(new Error "Package missing type for calling #{name}") unless type = pkg.get('type')
    try
      _Utils = require "./#{type}"
      return callback(new Error "Utils function not found for calling #{name} for type: #{type}") unless fn = _Utils[name]
      fn.apply(fn, args)
    catch err then return callback(err)

  @root: (pkg) -> path.dirname(pkg.get('path'))
  @cwd: (pkg) -> {cwd: Utils.root(pkg)}
