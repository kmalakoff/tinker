assert = assert or require?('chai').assert

describe 'tinker utils @quick @core', ->
  Tinker = window?.Tinker; try Tinker or= require?('tinker') catch; try Tinker or= require?('../../tinker')
  {_} = Tinker

  it 'TEST DEPENDENCY MISSING', (done) ->
    assert.ok(!!_, '_')
    done()

  it 'TODO', (done) ->
    return done()
