/*
  module.js 0.0.1
  Copyright (c)  2014-2014 Kevin Malakoff.
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/kmalakoff/tinker
  Dependencies: js-git and Underscore.js.
*/
var GitRepo, Module, PROPERTIES, Wrench, path, _;

path = require('path');

_ = require('underscore');

GitRepo = require('./git_repo');

Wrench = require('wrench');

PROPERTIES = ['name', 'root', 'path', 'url', 'package_url', 'owner'];

module.exports = Module = (function() {
  function Module(options) {
    var key, value, _i, _len, _ref;
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
    this.repo = new GitRepo({
      path: this.path,
      url: this.url || this.package_url
    });
  }

  Module.prototype.on = function(callback) {
    console.log("Tinkering on " + this.name + " (" + (this.path.replace("" + this.root + "/", '')) + ")");
    Wrench.rmdirSyncRecursive(this.path, true);
    return this.repo.clone(callback);
  };

  Module.prototype.off = function(callback) {
    console.log("Tinkering off " + this.name + " (" + (this.path.replace("" + this.root + "/", '')) + ")");
    Wrench.rmdirSyncRecursive(this.path, true);
    return this.owner.installModule(this, callback);
  };

  return Module;

})();
