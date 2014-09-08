/*
  npm_package.js 0.0.1
  Copyright (c)  2014-2014 Kevin Malakoff.
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/kmalakoff/tinker
  Dependencies: js-git and Underscore.js.
*/
var File, Module, NPMPackage, PROPERTIES, Queue, bower, es, fs, jsonFileParse, minimatch, path, rpt, spawn, _;

fs = require('fs');

path = require('path');

_ = require('underscore');

es = require('event-stream');

minimatch = require('minimatch');

File = require('vinyl');

jsonFileParse = require('./json_file_parse');

Queue = require('queue-async');

bower = require('bower');

Module = require('./module');

rpt = require('read-package-tree');

spawn = require('./spawn');

PROPERTIES = ['path', 'contents'];

module.exports = NPMPackage = (function() {
  function NPMPackage(options) {
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

  NPMPackage.prototype.modules = function(glob, callback) {
    var collectModules, directory;
    directory = path.dirname(this.path);
    collectModules = (function(_this) {
      return function(data, glob) {
        var child, name, results, _i, _len, _ref, _ref1, _ref2;
        results = [];
        if (minimatch(name = ((_ref = data["package"]) != null ? _ref.name : void 0) || '', glob)) {
          results.push(new Module({
            owner: _this,
            name: name,
            path: data.path,
            root: directory,
            url: (_ref1 = data["package"]) != null ? _ref1.url : void 0,
            package_url: _this.contents.dependencies[name]
          }));
        }
        _ref2 = data.children || [];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          child = _ref2[_i];
          results = results.concat(collectModules(child, glob));
        }
        return results;
      };
    })(this);
    return rpt(path.dirname(this.path), (function(_this) {
      return function(err, data) {
        return callback(null, collectModules(data, glob));
      };
    })(this));
  };

  NPMPackage.prototype.install = function(callback) {
    return spawn('npm install', {
      cwd: path.dirname(this.path)
    }, callback);
  };

  NPMPackage.prototype.installModule = function(module, callback) {
    return spawn("npm install " + module.name, {
      cwd: path.dirname(this.path)
    }, callback);
  };

  return NPMPackage;

})();
