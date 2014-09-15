assert = assert or require?('chai').assert
fs = require 'fs-extra'
path = require 'path'
Queue = require 'queue-async'

MODULE_DIRECTORIES = ['node_modules', 'bower_components']

describe 'tinker utils @quick @core', ->
  Tinker = require('../../src')

  before (callback) ->
    queue = new Queue(1)
    for directory in MODULE_DIRECTORIES
      do (directory) -> queue.defer (callback) -> fs.remove path.join(__dirname, '..', 'data', directory), -> callback()
    queue.defer (callback) -> Tinker.Config.load {directory: 'test/data'}, callback
    queue.defer (callback) -> Tinker.Config.clear().save(callback)
    queue.defer (callback) -> Tinker.cacheClear {directory: 'test/data'}, callback
    queue.await callback

  it 'configures', (callback) ->
    queue = new Queue(1)
    queue.defer (callback) ->
      Tinker.configure {package_types: 'npm'}, {directory: 'test/data'}, (err) ->
        assert.ok !err
        assert.equal Tinker.Config.get('package_types'), 'npm'
        callback()

    queue.defer (callback) ->
      Tinker.configure ['package_types=bower'], {directory: 'test/data'}, (err) ->
        assert.ok !err
        assert.equal Tinker.Config.get('package_types'), 'bower'
        callback()
    queue.await callback

  it 'initializes', (callback) ->
    Tinker.init {directory: 'test/data', force: true}, callback

  it 'installs', (callback) ->
    Tinker.install {directory: 'test/data', force: true}, callback

  it 'on', (callback) ->
    Tinker.on {directory: 'test/data', glob: 'underscore', force: true}, callback

  it 'off', (callback) ->
    Tinker.off {directory: 'test/data', glob: 'underscore', force: true}, callback

  it 'on with git cache', (callback) ->
    Tinker.on {directory: 'test/data', glob: 'underscore', force: true}, callback
