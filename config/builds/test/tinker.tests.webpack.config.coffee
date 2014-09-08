path = require 'path'
_ = require 'underscore'

module.exports = _.extend  _.clone(require '../../webpack/base-config.coffee'), {
  entry: _.flatten([require('../../files').tests_browser])
}

module.exports.resolve.alias =
  tinker: path.resolve('./tinker.js')
