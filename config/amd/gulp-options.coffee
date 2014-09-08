module.exports =
  karma: true,
  shims:
    underscore: {exports: '_'}
    tinker: {exports: 'TInker', deps: ['underscore']}
  post_load: 'window._ = window.Tinker = null;'
  aliases: {'tinker', 'lodash': 'underscore'}
