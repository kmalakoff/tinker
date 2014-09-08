path = require 'path'
Async = require 'async'
es = require 'event-stream'

gulp = require 'gulp'
gutil = require 'gulp-util'
coffee = require 'gulp-coffee'
rename = require 'gulp-rename'
uglify = require 'gulp-uglify'
header = require 'gulp-header'
mocha = require 'gulp-mocha'

HEADER = module.exports = """
/*
  <%= file.path.split('/').splice(-1)[0].replace('.min', '') %> <%= pkg.version %>
  Copyright (c)  2014-#{(new Date()).getFullYear()} Kevin Malakoff.
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/kmalakoff/tinker
  Dependencies: js-git and Underscore.js.
*/\n
"""

gulp.task 'build', buildLibraries = (callback) ->
  gulp.src('src/**/*.coffee')
    .pipe(coffee({bare: true}))
    .pipe(header(HEADER, {pkg: require('./package.json')}))
    .pipe(gulp.dest('lib'))
    .on('end', callback)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

testNode = (callback) ->
  tags = ("@#{tag.replace(/^[-]+/, '')}" for tag in process.argv.slice(3)).join(' ')

  gutil.log "Running Node.js tests #{tags}"
  gulp.src('test/spec/**/*.tests.coffee')
    .pipe(mocha({reporter: 'dot', grep: tags}))
    .pipe es.writeArray callback
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'test', ['build'], testNode
