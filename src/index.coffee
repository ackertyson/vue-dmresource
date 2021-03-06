unless window?.Vue? # Vue is loaded in <SCRIPT> tag; don't try 'require' it
  Vue = require 'vue'
VueResource = require 'vue-resource'
Vue = window.Vue if process.env.NODE_ENV is 'test' and window?.Vue?
Vue.use VueResource
Promise = require 'promise'
hs = require './helpers'

class DMResource
  constructor: (@name, routes) ->
    @base_url = '/api/' # default
    if routes? # build custom routes
      @_add_custom name, config for name, config of routes

  _name: (name) ->
    "VUE-DMRESOURCE: #{@name.toUpperCase()}.#{name}"

  _add_custom: (name, config) ->
    { url, method } = config
    exact = config.exact or false
    if name is "base" # override default base_url
      url += '/' unless url.slice(-1) is '/' # add trailing slash
      @base_url = url
      return
    slugs = url.split '/'
    wildcards = []
    named = {}
    rgx_named = /^:(\w+)/i # match named param
    for slug, i in slugs
      if slug is '?' # wildcard parameter (e.g., /api/type/?/items)
        throw new Error "#{@_name name} can't use both wildcard (?) and named (:param) parameters" if Object.keys(named).length > 0
        wildcards.push i # record position of param in URL
      else if rgx_named.test slug # named param (e.g., /api/type/:id/items)
        throw new Error "#{@_name name} can't use both wildcard (?) and named (:param) parameters" if wildcards.length > 0
        arr = slug.match rgx_named
        named[arr[1]] = i # record position of named param in URL

    @[name] = (args...) => # return partially applied function to component
      _args = args.slice 1 # cut URL out of ARGS
      if wildcards.length > 0 # handler uses wildcard (?) params
        return Promise.reject new Error "#{@_name name} expects at least #{wildcards.length} params, only got #{args.length}" unless wildcards.length <= args.length
        return Promise.reject new Error "#{@_name name}: use named parameters if you want to pass them in an object" if wildcards.length > 0 and hs.typeof(args[0]) is 'object'
        for param, i in wildcards # substitute args for any expected params
          slugs[param] = args[i]
        _args = args.slice wildcards.length # cut URL params out of ARGS
      else if Object.keys(named).length > 0 # handler uses named params
        if method.toLowerCase() in ['patch', 'post', 'put'] # BODY expected
          [params, body, options] = args
          params ?= body # use BODY if no PARAMS provided
          _args = [body, options]
        else # no BODY for this METHOD
          [params, options] = args
          _args = [options]
        return Promise.reject new Error "#{@_name name} uses named parameters; pass them as an object" unless hs.typeof(params) is 'object'
        for param, i of named
          return Promise.reject new Error "#{@_name name} expects '#{param}' parameter" unless params[param]?
          slugs[i] = params[param]

      url = slugs.join '/'
      url = url.slice(1) if url.slice(0, 1) is '/' # trim leading slash
      try # catch bad METHODS, etc...
        url = "#{@base_url}#{@name}/#{url}" unless exact is true
        Vue.http[method.toLowerCase()](url, _args...).then (data) ->
          data.body
      catch ex
        console.log "[vue-dmresource]:", ex


  all: (options) ->
    Vue.http.get("#{@base_url}#{@name}", options).then (data) ->
      data.body

  create: (body, options) ->
    Vue.http.post("#{@base_url}#{@name}", body, options).then (data) ->
      data.body

  delete: (id, options) ->
    Vue.http.delete("#{@base_url}#{@name}/#{id}", options).then (data) ->
      data.body

  find_by_id: (id, options) ->
    Vue.http.get("#{@base_url}#{@name}/#{id}", options).then (data) ->
      data.body

  update: (id, body, options) ->
    Vue.http.put("#{@base_url}#{@name}/#{id}", body, options).then (data) ->
      data.body


module.exports = DMResource
