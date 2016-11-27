unless window?.Vue? # Vue is loaded in <SCRIPT> tag; don't try 'require' it
  Vue = require 'vue'
  VueResource = require 'vue-resource'
Vue = window.Vue if process.env.NODE_ENV is 'test'
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
    try # for reasons not entirely clear to me, certain errors in this block get swallowed whole unless we try/catch them...
      for slug, i in slugs
        if slug is '?' # wildcard parameter (e.g., /api/type/?/items)
          throw new Error "#{@_name name} can't use both wildcard (?) and named (:param) parameters" if Object.keys(named).length > 0
          wildcards.push i # record position of param in URL
        else if rgx_named.test slug # named param (e.g., /api/type/:id/items)
          throw new Error "#{@_name name} can't use both wildcard (?) and named (:param) parameters" if wildcards.length > 0
          arr = slug.match rgx_named
          named[arr[1]] = i # record position of named param in URL
    catch ex
      return false

    @[name] = (args...) => # return partially applied function to component
      if wildcards.length > 0 # handler uses wildcard (?) params
        return Promise.reject new Error "#{@_name name} expects at least #{wildcards.length} params, only got #{args.length}" unless wildcards.length <= args.length
        return Promise.reject new Error "#{@_name name}: use named parameters if you want to pass them in an object" if wildcards.length > 0 and hs.typeof(args[0]) is 'object'
        for param, i in wildcards # substitute args for any expected params
          slugs[param] = args[i]
      else if Object.keys(named).length > 0 # handler uses named params
        return Promise.reject new Error "#{@_name name} uses named parameters; pass them as an object" unless hs.typeof(args[0]) is 'object'
        for param, i of named
          return Promise.reject new Error "#{@_name name} expects '#{param}' parameter" unless args[0]?[param]?
          slugs[i] = args[0][param]

      url = slugs.join '/'
      url = url.slice(1) if url.slice(0, 1) is '/' # trim leading slash
      try # catch bad METHODS, etc...
        url = "#{@base_url}#{@name}/#{url}" unless exact
        Vue.http[method.toLowerCase()](url, args...).then (data) ->
          data.body
        .catch (err) ->
          console.log err
          err
      catch ex
        console.log ex


  all: (options) ->
    Vue.http.get("#{@base_url}#{@name}", options).then (data) ->
      data.body
    .catch (err) ->
      console.log err
      err

  create: (body, options) ->
    Vue.http.post("#{@base_url}#{@name}", body, options).then (data) ->
      data.body
    .catch (err) ->
      console.log err
      err

  delete: (id, options) ->
    Vue.http.delete("#{@base_url}#{@name}/#{id}", options).then (data) ->
      data.body
    .catch (err) ->
      console.log err
      err

  find_by_id: (id, options) ->
    Vue.http.get("#{@base_url}#{@name}/#{id}", options).then (data) ->
      data.body
    .catch (err) ->
      console.log err
      err

  update: (id, body, options) ->
    Vue.http.put("#{@base_url}#{@name}/#{id}", body, options).then (data) ->
      data.body
    .catch (err) ->
      console.log err
      err


module.exports = DMResource
