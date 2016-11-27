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
`ApiName = new API name, [custom_route_config]`

`ApiName` is how you refer to the API in your component; `name` will be appended
to each request URL (see above) and would typically correspond to a subroute of
your backend API; see below for `custom_route_config` example.

You can specify an exact URL by including `exact: true` in your route
definition.

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

Vue.extend
  name: 'work_order'
  data: () ->
    items: []
    notes: []
  mounted: () ->
    WorkOrder.get_notes(1000234).then (notes) ->
      @notes = notes
      WorkOrder.get_items({ id: 1000999 }).then (items) ->
        @items = items
    .catch (err) ->
      console.log err
```

##Testing
`npm test`
