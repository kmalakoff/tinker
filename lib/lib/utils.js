/*
  utils.js 0.0.1
  Copyright (c)  2014-2014 Kevin Malakoff.
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/kmalakoff/tinker
  Dependencies: js-git and Underscore.js.
*/
var MODULES, Queue, Utils, Vinyl, es, jsonFileParse, path, _;

path = require('path');

_ = require('underscore');

Queue = require('queue-async');

Vinyl = require('vinyl-fs');

es = require('event-stream');

jsonFileParse = require('./json_file_parse');

MODULES = {
  bower: {
    package_name: 'bower.json',
    Class: require('./bower_package')
  },
  npm: {
    package_name: 'package.json',
    Class: require('./npm_package')
  }
};

module.exports = Utils = (function() {
  function Utils() {}

  Utils.packages = function(directory, options, callback) {
    var info, key, module_options, modules, name, value, _ref;
    if (arguments.length === 2) {
      _ref = [{}, options], options = _ref[0], callback = _ref[1];
    }
    if (_.size(module_options = _.pick(options, _.keys(MODULES)))) {
      modules = {};
      for (key in module_options) {
        value = module_options[key];
        if (!!value) {
          modules[key] = MODULES[key];
        }
      }
    } else {
      modules = MODULES;
    }
    return Vinyl.src((function() {
      var _results;
      _results = [];
      for (name in modules) {
        info = modules[name];
        _results.push(path.join(directory, info.package_name));
      }
      return _results;
    })()).pipe(es.map(function(file, callback) {
      return jsonFileParse(file, function(err, parsed_file) {
        return callback(err, parsed_file);
      });
    })).pipe(es.writeArray(function(err, files) {
      var file, info, package_name, packages, _i, _len;
      if (err) {
        return callback(err);
      }
      packages = [];
      for (_i = 0, _len = files.length; _i < _len; _i++) {
        file = files[_i];
        package_name = path.basename(file.path);
        info = _.find(MODULES, function(info, name) {
          return info.package_name === package_name;
        });
        packages.push(new info.Class(file));
      }
      return callback(null, packages);
    }));
  };

  Utils.modules = function(directory, glob, options, callback) {
    return Utils.packages(directory, options, function(err, packages) {
      var modules, pkg, queue, _fn, _i, _len;
      if (err) {
        return callback(err);
      }
      modules = [];
      queue = new Queue();
      _fn = function(pkg) {
        return queue.defer(function(callback) {
          return pkg.modules(glob, function(err, _modules) {
            modules = modules.concat(_modules);
            return callback(err);
          });
        });
      };
      for (_i = 0, _len = packages.length; _i < _len; _i++) {
        pkg = packages[_i];
        _fn(pkg);
      }
      return queue.await(function(err) {
        if (err) {
          callback(err);
        }
        return callback(null, modules);
      });
    });
  };

  return Utils;

})();
