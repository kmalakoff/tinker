path = require 'path'
_ = require 'underscore'
Wrench = require 'wrench'

module.exports =
  tests_webpack: ("./config/builds/test/#{filename}" for filename in Wrench.readdirSyncRecursive(__dirname + '/builds/test') when /\.webpack.config.coffee$/.test(filename))
  tests_browser: ("./test/spec/#{filename}" for filename in Wrench.readdirSyncRecursive(__dirname + '/../test/spec') when /\.tests.coffee$/.test(filename))
