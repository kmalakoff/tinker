###
  tinker.js 0.0.1
  Copyright (c) 2013-2014 Kevin Malakoff
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/kmalakoff/tinker
  Dependencies: js-git and Underscore.js.
###

_ = require 'underscore'
Tinker = require '../core'

# set up defaults

module.exports = (options={}) ->
  Tinker[key] = value for key, value of options
