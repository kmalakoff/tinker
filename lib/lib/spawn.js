/*
  spawn.js 0.0.1
  Copyright (c)  2014-2014 Kevin Malakoff.
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/kmalakoff/tinker
  Dependencies: js-git and Underscore.js.
*/
var spawn, _;

spawn = require('child_process').spawn;

_ = require('underscore');

module.exports = function(cmd, options, callback) {
  var args, child, cmd_parts, done, _ref;
  if (options == null) {
    options = {};
  }
  if (arguments.length === 2) {
    _ref = [{}, options], options = _ref[0], callback = _ref[1];
  }
  done = _.after(callback = _.once(callback), 3);
  cmd_parts = cmd.split(' ');
  args = [cmd_parts.shift(), cmd_parts];
  options = _.clone(options);
  options.env = options.env ? _.extend({}, options.env, process.env) : process.env;
  args.push(options);
  child = spawn.apply(null, args);
  child.stderr.on('error', callback);
  child.stderr.on('data', (function(_this) {
    return function(chunk) {
      return process.stdout.write(chunk.toString());
    };
  })(this));
  child.stderr.on('end', done);
  child.stdout.on('error', callback);
  child.stdout.on('data', (function(_this) {
    return function(chunk) {
      return process.stdout.write(chunk.toString());
    };
  })(this));
  child.stdout.on('end', done);
  child.on('error', callback);
  return child.on('exit', function() {
    return done();
  });
};
