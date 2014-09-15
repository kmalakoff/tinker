assert = assert or require?('chai').assert
Queue = require 'queue-async'

describe 'tinker utils @quick @core', ->
  Tinker = require('../../src')

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

  it 'clears the cache', (callback) ->
    Tinker.cacheClear {directory: 'test/data'}, callback

  it 'uninstalls', (callback) ->
    Tinker.uninstall {directory: 'test/data', force: true}, callback

  it 'installs', (callback) ->
    Tinker.install {directory: 'test/data', force: true}, callback

  it 'on', (callback) ->
    Tinker.on {directory: 'test/data', glob: 'underscore', force: true}, callback

  it 'off', (callback) ->
    Tinker.off {directory: 'test/data', glob: 'underscore', force: true}, callback
