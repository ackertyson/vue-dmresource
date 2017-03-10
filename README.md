#vue-dmresource

Convenience wrapper for VueResource to provide API layer in Vue web app. Common
handlers are built in. Custom route descriptors can be passed into
constructor; any '?' wildcards in URL will be replaced in order with arguments
passed to handler, or named params (:param) can be passed as object. Base URL
can be provided as a custom route named "base" (see example below).

Request URL is concatenated like so: `BASE_URL/NAME/CUSTOM_ROUTE_URL`; for
example: `/api/work_order/?/notes` (unless `exact` prop is set; see below).

##Installation
`npm i --save vue-dmresource`

##Basic Usage
```
API = require 'vue-dmresource'
MyApi = new API name [, custom_route_config]
```

`MyApi` is (in this example) how you refer to the API in your component; `name`
will be appended to each request URL (see above) and would typically correspond
to a subroute of your backend API; see example below.

You can specify an exact URL by including `exact: true` in your route
definition. Including a leading `/` will cause that URL to be interpreted
relative to `window.location.host` (the site document root); omitting the
leading slash makes it a relative URL; including a protocol (`http://`) will
allow you to specify the exact URL from start to finish.

When using named URL parameters in custom methods, verbs `PATCH`, `POST` and
`PUT` require that all parameters be contained in the BODY of the request, which
is the only required argument to the method (the VueResource `options` object is
the optional second argument). If your URL parameters can't be included in the
BODY, you should use wildcard (?) parameters instead.

Using named parameters with custom `PUT` methods can be convenient when the
value(s) you want to use as the URL parameter(s) are contained in the body of the
request. In that case, just name your URL parameter(s) the same as the name of the
body key(s) which contains those values and they will be parsed automagically.

##Example component
```
Vue = require 'vue' # omit if Vue is loaded in <SCRIPT> tag
API = require 'vue-dmresource'
WorkOrder = new API 'work_order',
  base: # optional baseUrl prepended to all requests (default is '/api')
    url: '/api/v1'
  get_notes: # route with wildcard parameter(s)
    method: 'get'
    url: '/?/notes'
  get_items: # route with named parameter(s)
    method: 'get'
    url: '/:id/items'
  get_others: # route with exact URL
    method: 'get'
    url: '/not_api/?/all/different'
    exact: true
  get_external: # route with complete exact URL
    method: 'get'
    url: 'http://other-external-web-site.com/items/?'
    exact: true
  update_item:
    method: 'put'
    url: '/item/?'
  update_item_named:
    method: 'put'
    url: '/item/:id'

Vue.extend
  name: 'wo-component'
  data: () ->
    items: []
    notes: []
  mounted: () ->
    WorkOrder.get_notes(1234).then (notes) ->
      @notes = notes
      WorkOrder.get_items({ id: 1999 }).then (items) ->
        @items = items
    .catch (err) ->
      console.log err

    WorkOrder.update_item(1234, { name: 'Made up' }).then (data) ->
      # wildcard ('?') ID param provided explicitly
      updated_item = data

    WorkOrder.update_item_named({ id: 1234, name: 'Made up' }).then (data) ->
      # named ID param will be pulled from provided BODY
      updated_item = data
```

##Testing
`npm test`
