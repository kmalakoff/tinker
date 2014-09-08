/*
  git_repo.js 0.0.1
  Copyright (c)  2014-2014 Kevin Malakoff.
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/kmalakoff/tinker
  Dependencies: js-git and Underscore.js.
*/
var Git, GitRepo, PROPERTIES, _;

_ = require('underscore');

Git = require('nodegit');

PROPERTIES = ['path', 'url'];

module.exports = GitRepo = (function() {
  function GitRepo(options) {
    var key, value, _i, _len, _ref;
    _ref = _.pick(options, PROPERTIES);
    for (key in _ref) {
      value = _ref[key];
      this[key] = value;
    }
    for (_i = 0, _len = PROPERTIES.length; _i < _len; _i++) {
      key = PROPERTIES[_i];
      if (!this.hasOwnProperty(key)) {
        throw new Error("GitRepo missing " + key);
      }
    }
  }

  GitRepo.prototype.clone = function(callback) {
    return Git.Repo.clone(this.url, this.path, null, (function(_this) {
      return function(err, repo) {
        return callback(err);
      };
    })(this));
  };

  return GitRepo;

})();
