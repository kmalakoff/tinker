es = require 'event-stream'

gulp = require 'gulp'
gutil = require 'gulp-util'
mocha = require 'gulp-mocha'

testNode = (callback) ->
  tags = ("@#{tag.replace(/^[-]+/, '')}" for tag in process.argv.slice(3)).join(' ')

  gutil.log "Running Node.js tests #{tags}"
  gulp.src('test/spec/**/*.tests.coffee')
    .pipe(mocha({reporter: 'dot', grep: tags, timeout: 20000}))
    .pipe es.writeArray callback
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'test', testNode
