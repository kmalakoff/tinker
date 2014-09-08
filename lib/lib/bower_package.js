/*
  bower_package.js 0.0.1
  Copyright (c)  2014-2014 Kevin Malakoff.
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/kmalakoff/tinker
  Dependencies: js-git and Underscore.js.
*/
var BowerPackage, File, Module, PROPERTIES, Queue, bower, es, fs, jsonFileParse, minimatch, path, spawn, _;

fs = require('fs');

path = require('path');

_ = require('underscore');

es = require('event-stream');

minimatch = require('minimatch');

File = require('vinyl');

jsonFileParse = require('./json_file_parse');

Queue = require('queue-async');

Module = require('./module');

bower = require('bower');

spawn = require('./spawn');

PROPERTIES = ['path', 'contents'];

module.exports = BowerPackage = (function() {
  function BowerPackage(options) {
    var key, value, _base, _i, _len, _ref;
    _ref = _.pick(options, PROPERTIES);
    for (key in _ref) {
      value = _ref[key];
      this[key] = value;
    }
    for (_i = 0, _len = PROPERTIES.length; _i < _len; _i++) {
      key = PROPERTIES[_i];
      if (!this.hasOwnProperty(key)) {
        throw new Error("Module missing " + key);
      }
    }
    (_base = this.contents).dependencies || (_base.dependencies = {});
  }

  BowerPackage.prototype.modules = function(glob, callback) {
    var directory;
    directory = path.dirname(this.path);
    return fs.readdir(path.join(directory, 'bower_components'), (function(_this) {
      return function(err, files) {
        var file;
        if (err) {
          return callback(err);
        }
        return es.readArray((function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = files.length; _i < _len; _i++) {
            file = files[_i];
            if (minimatch(file, glob)) {
              _results.push(file);
            }
          }
          return _results;
        })()).pipe(es.map(function(file_name, callback) {
          var module_path;
          module_path = path.join(directory, 'bower_components', file_name);
          return fs.exists(path.join(module_path, 'bower.json'), function(exists) {
            if (!exists) {
              return callback();
            }
            callback = _.once(callback);
            return bower.commands.lookup(file_name).on('error', callback).on('end', function(info) {
              var url;
              return callback(null, new Module({
                owner: _this,
                name: file_name,
                path: module_path,
                root: directory,
                url: url = info != null ? info.url : void 0,
                package_url: _this.contents.dependencies[file_name]
              }));
            });
          });
        })).pipe(es.writeArray(callback));
      };
    })(this));
  };

  BowerPackage.prototype.install = function(callback) {
    return spawn('bower install', {
      cwd: path.dirname(this.path)
    }, callback);
  };

  BowerPackage.prototype.installModule = function(module, callback) {
    return spawn("bower install " + module.name, {
      cwd: path.dirname(this.path)
    }, callback);
  };

  return BowerPackage;

})();
