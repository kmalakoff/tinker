URL = require 'url'

# based on https://github.com/visionmedia/node-github-url-from-git.git
REGEX =
  default: new RegExp(
    /^(?:https?:\/\/|git:\/\/|git\+ssh:\/\/|git\+https:\/\/)?/.source +
    '([0-9A-Za-z-\\.@:%_\+~#=]+)' +
    /[:\/]([^\/]+\/[^\/]+?|[0-9]+)$/.source
  )

  parts: new RegExp(
    /^(?:https?:\/\/|git:\/\/|git\+ssh:\/\/|git\+https:\/\/)?/.source +
    '([0-9A-Za-z-\\.@:%_\+~#=]+)' +
    /[:\/]([^\/]+\/[^\/]+?|[0-9]+)$/.source
  )

module.exports = class RepoURL
  @isValid: (url) -> !!RepoURL.parseURL(url)
  @parse: (url) ->
    try
      if match = REGEX.default.exec(url?.replace(/\.git(#.*)?$/, '') or '')
        return {url: "https://#{match[1]}/#{match[2]}", auth: null, tag: null}

  @format: (parts) ->
    return unless url = parts?.url
    if parts.auth

      URL.parse(url)


  @normalize: (url) ->
    console.log url, RepoUtils.parseURL(url)
    try
      return "https://#{match[1]}/#{match[2]}" if match = REGEX.default.exec(url?.replace(/\.git(#.*)?$/, '') or '')
