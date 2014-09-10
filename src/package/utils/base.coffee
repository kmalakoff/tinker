path = require 'path'

module.exports = class Utils
  @root: (pkg) -> path.dirname(pkg.get('path'))
  @cwd: (pkg) -> {cwd: Utils.root(pkg)}
