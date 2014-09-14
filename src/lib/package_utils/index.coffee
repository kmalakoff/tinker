path = require 'path'

cache = {}

module.exports = class Utils
  @lookup: (pkg, name) ->
    throw new Error "Package missing type for calling #{name}" unless type = pkg.get('type')
    SpecializedUtils = cache[type] or= require "./#{type}"
    throw new Error "Utils function not found for calling #{name} for type: #{type}" unless fn = SpecializedUtils[name]
    fn.bind(fn, pkg)

  @root: (pkg) -> path.dirname(pkg.get('path'))
  @cwd: (pkg) -> {cwd: Utils.root(pkg)}
