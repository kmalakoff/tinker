/*
  index.js 0.0.1
  Copyright (c)  2014-2014 Kevin Malakoff.
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/kmalakoff/tinker
  Dependencies: js-git and Underscore.js.
*/
var Async, Tinker, Utils, colors, es, fs, path;

fs = require('fs');

path = require('path');

es = require('event-stream');

colors = require('colors');

Async = require('async');

Utils = require('./lib/utils');

module.exports = Tinker = (function() {
  function Tinker() {}

  Tinker.install = function(options, callback) {
    var directory, _ref;
    if (arguments.length === 1) {
      _ref = [{}, options], options = _ref[0], callback = _ref[1];
    }
    directory = options.directory ? path.join(process.cwd(), options.directory) : process.cwd();
    return Utils.packages(directory, options, function(err, packages) {
      if (err) {
        console.error(("failed " + err).red);
        callback(err);
      }
      return Async.each(packages, (function(pkg, callback) {
        return pkg.install(callback);
      }), function(err) {
        if (err) {
          console.error(("failed " + err).red);
          callback(err);
        }
        return callback();
      });
    });
  };

  Tinker.on = function(glob, options, callback) {
    var directory, _ref;
    if (arguments.length === 2) {
      _ref = [{}, options], options = _ref[0], callback = _ref[1];
    }
    directory = options.directory ? path.join(process.cwd(), options.directory) : process.cwd();
    return Utils.modules(directory, glob, options, function(err, modules) {
      if (err) {
        console.error(("failed " + err).red);
        callback(err);
      }
      return Async.each(modules, (function(module, callback) {
        return module.on(callback);
      }), function(err) {
        if (err) {
          console.error(("failed " + err).red);
          callback(err);
        }
        return callback();
      });
    });
  };

  Tinker.off = function(glob, options, callback) {
    var directory, _ref;
    if (arguments.length === 2) {
      _ref = [{}, options], options = _ref[0], callback = _ref[1];
    }
    directory = options.directory ? path.join(process.cwd(), options.directory) : process.cwd();
    return Utils.modules(directory, glob, options, function(err, modules) {
      if (err) {
        console.error(("failed " + err).red);
        callback(err);
      }
      return Async.each(modules, (function(module, callback) {
        return module.off(callback);
      }), function(err) {
        if (err) {
          console.error(("failed " + err).red);
          callback(err);
        }
        return callback();
      });
    });
  };

  return Tinker;

})();
