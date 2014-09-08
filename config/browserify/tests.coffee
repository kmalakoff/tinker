module.exports =
  tinker:
    output: './_temp/browserify/tinker.tests.js'
    files: ['./test/spec/**/*.tests.coffee']
    options:
      shim:
        tinker: {path: './tinker.js', exports: 'Tinker', depends: {underscore: '_'}}
