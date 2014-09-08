/*
  json_file_parse.js 0.0.1
  Copyright (c)  2014-2014 Kevin Malakoff.
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/kmalakoff/tinker
  Dependencies: js-git and Underscore.js.
*/
var File, es, _;

_ = require('underscore');

es = require('event-stream');

File = require('vinyl');

module.exports = function(file, callback) {
  return file.pipe(es.wait(function(err, contents) {
    if (err) {
      return callback(err);
    }
    try {
      return callback(null, _.extend({
        contents: JSON.parse(contents)
      }, _.pick(file, 'cwd', 'base', 'path')));
    } catch (_error) {
      err = _error;
      return callback(err);
    }
  }));
};
