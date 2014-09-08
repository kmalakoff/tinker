###
  tinker.js 0.0.1
  Copyright (c) 2013-2014 Kevin Malakoff
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/kmalakoff/tinker
  Dependencies: js-git and Underscore.js.
###

_ = require 'underscore'

module.exports = Tinker = require './core' # avoid circular dependencies
publish =
  configure: require './lib/configure'

  Utils: require './lib/utils'
  Queue: require './lib/queue'

  _: _
_.extend(Tinker, publish)

# re-expose modules
Tinker.modules =
  underscore: _
