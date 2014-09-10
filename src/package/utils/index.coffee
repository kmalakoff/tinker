module.exports = class Utils
  @TYPES =
    bower: require './bower'
    npm: require './npm'

  @call: (pkg, name, args) ->
    args = Array::slice.call(args); args.unshift(pkg); callback = args[args.length-1]
    return callback(new Error "Package missing type for calling #{name}") unless type = pkg.get('type')
    return callback(new Error "Utils missing for calling #{name} for type: #{type}") unless PackageUtils = Utils.TYPES[type]
    return callback(new Error "Utils function not found for calling #{name} for type: #{type}") unless fn = PackageUtils[name]
    fn.apply(fn, args)
