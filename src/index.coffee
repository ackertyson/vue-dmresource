unless window?.Vue? # Vue is loaded in <SCRIPT> tag; don't try 'require' it
  Vue = require 'vue'
  VueResource = require 'vue-resource'
Vue.use VueResource
hs = require './helpers'

class DMResource
  constructor: (@name, routes) ->
    @base_url = '/api/' # default
    if routes? # build custom routes
      @_add_custom name, route.url, route.method for name, route of routes

  _name: (name) ->
    "API: #{@name.toUpperCase()}.#{name}"

  _add_custom: (name, url, method) ->
    if name is "base" # override default base_url
      url += '/' unless url.slice(-1) is '/' # add trailing slash
      @base_url = url
    slugs = url.split '/'
    wildcards = []
    named = {}
    rgx_named = new RegExp /^:(\w+)/, 'i' # match named param
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
      console.log ex
      return false

    @[name] = (args...) => # return partially applied function to component
      if wildcards.length > 0 # handler uses wildcard (?) params
        throw new Error "#{@_name name} expects at least #{wildcards.length} params, only got #{args.length}" unless wildcards.length <= args.length
        throw new Error "#{@_name name}: use named parameters if you want to pass them in an object" if wildcards.length > 0 and hs.typeof(args[0]) is 'object'
        for param, i in wildcards # substitute args for any expected params
          slugs[param] = args[i]
      else if Object.keys(named).length > 0 # handler uses named params
        throw new Error "#{@_name name} uses named parameters; pass them as an object" unless hs.typeof(args[0]) is 'object'
        for param, i of named
          throw new Error "#{@_name name} expects '#{param}' parameter" unless args[0]?[param]?
          slugs[i] = args[0][param]

      url = slugs.join '/'
      url = url.slice(1) if url.slice(0, 1) is '/' # trim leading slash
      try # catch bad METHODS, etc...
        Vue.http[method.toLowerCase()]("#{@base_url}#{@name}/#{url}", args...).then (data) ->
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
