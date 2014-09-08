path = require 'path'
_ = require 'underscore'
gutil = require 'gulp-util'
FILES = require './files'

resolveModule = (module_name) -> path.relative('.', require.resolve(module_name))

module.exports = TEST_GROUPS = {}

###############################
# Browser Globals
###############################
LIBRARIES =
  underscore: (resolveModule(module_name) for module_name in ['underscore']).concat(['./tinker.js'])
  underscore_min: (resolveModule(module_name) for module_name in ['underscore']).concat(['./tinker.min.js'])

TEST_SOURCES = ['./test/spec/**/*.tests.coffee']

TEST_GROUPS.browser_globals = []
for library_name, library_files of LIBRARIES
  TEST_GROUPS.browser_globals.push({name: "browser_globals_#{library_name}", files: library_files.concat(TEST_SOURCES)})

###############################
# AMD
###############################
AMD_LIBRARIES = {}
for library_name, library_files of LIBRARIES when not (/^legacy_|^parse_|_min$/).test(library_name)
  AMD_LIBRARIES[library_name] = [].concat(library_files)
  AMD_LIBRARIES["#{library_name}_no_stream"] = library_files

AMD_OPTIONS = require './amd/gulp-options'
TEST_GROUPS.amd = []
for library_name, library_files of AMD_LIBRARIES
  test_files = ['./node_modules/chai/chai.js'].concat(library_files, TEST_SOURCES); files = []; test_patterns = []; path_files = []
  files.push({pattern: './test/lib/requirejs-2.1.14.js'})
  for file in test_files
    (test_patterns.push(file); continue) if file.indexOf('.tests.') >= 0
    files.push({pattern: file, included: false})
    path_files.push(file)
  files.push("_temp/amd/#{library_name}/**/*.js")
  amd_options = _.extend({path_files: path_files}, AMD_OPTIONS)
  TEST_GROUPS.amd.push({name: "amd_#{library_name}", files: files, build: {files: test_patterns, destination: "_temp/amd/#{library_name}", options: amd_options}})

###############################
# Webpack
###############################
TEST_GROUPS.webpack = []
for file in FILES.tests_webpack
  test_file = path.basename(file, '.js').replace('.webpack.config', '')
  TEST_GROUPS.webpack.push({name: "webpack_#{test_file.replace('tests.coffee', '')}", files: [path.join('_temp/webpack', test_file).replace('.coffee', '.js')]})

###############################
# Browserify
###############################
TEST_GROUPS.browserify = []
for test_name, test_info of require './browserify/tests'
  TEST_GROUPS.browserify.push({name: "browserify_#{test_name}", files: [test_info.output], build: {destination: test_info.output, options: test_info.options, files: test_info.files}})
