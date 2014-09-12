class Config extends (require './disk_model')
  url: './.tinker'
  defaults: {modules: []}

module.exports = new Config()
