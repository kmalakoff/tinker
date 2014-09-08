path = require 'path'
_ = require 'underscore'

module.exports = _.extend  _.clone(require '../../webpack/base-config.coffee'), {
  entry: _.flatten(['./src/index.coffee'])
  output:
    library: 'Tinker'
    libraryTarget: 'umd2'

  externals: [
    {underscore: {root: '_', amd: 'underscore', commonjs: 'underscore', commonjs2: 'underscore'}}
  ]
}
