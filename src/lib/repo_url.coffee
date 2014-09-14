URL = require 'url'
endpointParser = require('bower-endpoint-parser')

# based on https://github.com/visionmedia/node-github-url-from-git.git
REGEX = new RegExp(
  /^(?:https?:\/\/|git:\/\/|git\+ssh:\/\/|git\+https:\/\/)?/.source +
  '([0-9A-Za-z-\\.@:%_\+~#=]+)' +
  /[:\/]([^\/]+\/[^\/]+?|[0-9]+)$/.source
)

module.exports = class RepoURL
  @isValid: (url) -> !!RepoURL.parse(url)
  @parse: (url) ->
    try
      parts = endpointParser.decompose(url)
      parts.source = "https://#{match[1]}/#{match[2]}" if match = REGEX.exec(parts.source?.replace(/\.git(#.*)?$/, '') or '')
      parts[key] = '' for key, value of parts when value is '*'
      return parts if parts.source

  @format: (parts) -> return unless parts; endpointParser.compose(parts)
  @normalize: (url) -> RepoURL.format(RepoURL.parse(url))
