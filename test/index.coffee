chai = require 'chai'
expect = chai.expect
should = chai.should()
Promise = require 'promise'
dom = require('jsdomify').default

describe 'vue-dmresource', ->
  before (done) ->
    dom.create()
    window.Vue = # mock VueResource; simply return slugified URL (and body)
      http:
        delete: (url, options) ->
          slugs = url.split('/')
          Promise.resolve body: slugs
        get: (url, options) ->
          slugs = url.split('/')
          Promise.resolve body: slugs
        post: (url, r_body, options) ->
          slugs = url.split('/')
          Promise.resolve body: [slugs, r_body]
        put: (url, r_body, options) ->
          slugs = url.split('/')
          Promise.resolve body: [slugs, r_body]
      use: ->
    @resource = require '../src'
    done()


  describe 'constructor', ->
    it 'should set name and default URL', ->
      Api = new @resource 'API'
      Api.name.should.equal 'API'
      Api.base_url.should.equal '/api/'

    it 'should honor provided URL', ->
      Api = new @resource 'API', base: { url: '/different/path/' }
      Api.base_url.should.equal '/different/path/'

    it 'should create custom handler', ->
      Api = new @resource 'API',
        custom:
          method: 'get'
          url: '/custom/url'
      expect(Api.custom).to.be.a.function


  describe 'BUILT-INS', ->
    describe 'all', ->
      it 'should request to correct URL', ->
        Api = new @resource 'all'
        Api.all().then (data) ->
          data.should.have.length 3
          data[0].should.equal ''
          data[1].should.equal 'api'
          data[2].should.equal 'all'

      it 'should request to correct URL when base is provided', ->
        Api = new @resource 'all',
          base:
            url: 'http://localhost:8080/api/'
        Api.all().then (data) ->
          data.should.have.length 5
          data[0].should.equal 'http:'
          data[1].should.equal ''
          data[2].should.equal 'localhost:8080'
          data[3].should.equal 'api'
          data[4].should.equal 'all'

    describe 'create', ->
      it 'should request to correct URL', ->
        Api = new @resource 'fake'
        Api.create({ main: 'hi there' }).then (data) ->
          [slugs, body] = data
          slugs.should.have.length 3
          slugs[0].should.equal ''
          slugs[1].should.equal 'api'
          slugs[2].should.equal 'fake'
          body.should.have.property 'main', 'hi there'

    describe 'delete', ->
      it 'should request to correct URL', ->
        Api = new @resource 'fake'
        Api.delete(1234).then (data) ->
          data.should.have.length 4
          data[0].should.equal ''
          data[1].should.equal 'api'
          data[2].should.equal 'fake'
          data[3].should.equal '1234'

    describe 'find_by_id', ->
      it 'should request to correct URL', ->
        Api = new @resource 'fake'
        Api.find_by_id(1234).then (data) ->
          data.should.have.length 4
          data[0].should.equal ''
          data[1].should.equal 'api'
          data[2].should.equal 'fake'
          data[3].should.equal '1234'

    describe 'update', ->
      it 'should request to correct URL', ->
        Api = new @resource 'fake'
        Api.update(1234, { main: 'hi there' }).then (data) ->
          [slugs, body] = data
          slugs.should.have.length 4
          slugs[0].should.equal ''
          slugs[1].should.equal 'api'
          slugs[2].should.equal 'fake'
          slugs[3].should.equal '1234'
          body.should.have.property 'main', 'hi there'


  describe 'CUSTOM', ->
    describe 'delete', ->
      it 'should request to correct URL', ->
        Api = new @resource 'fake',
          custom:
            method: 'delete'
            url: '/thing/:id'
        Api.custom({ id: 1234 }).then (data) ->
          data.should.have.length 5
          data[0].should.equal ''
          data[1].should.equal 'api'
          data[2].should.equal 'fake'
          data[3].should.equal 'thing'
          data[4].should.equal '1234'


    describe 'get', ->
      it 'single wildcard param', ->
        Api = new @resource 'fake',
          custom:
            method: 'get'
            url: '/thing/?'
        Api.custom(1234).then (data) ->
          data.should.have.length 5
          data[0].should.equal ''
          data[1].should.equal 'api'
          data[2].should.equal 'fake'
          data[3].should.equal 'thing'
          data[4].should.equal '1234'

      it 'single wildcard param with options', ->
        Api = new @resource 'fake',
          custom:
            method: 'get'
            url: '/thing/?'
        Api.custom(1234, headers: { Auth: 'junk' }).then (data) ->
          data.should.have.length 5
          data[0].should.equal ''
          data[1].should.equal 'api'
          data[2].should.equal 'fake'
          data[3].should.equal 'thing'
          data[4].should.equal '1234'

      it 'multiple wildcard params', ->
        Api = new @resource 'fake',
          custom:
            method: 'get'
            url: '/thing/?/stuff/?'
        Api.custom(1234, 5678).then (data) ->
          data.should.have.length 7
          data[0].should.equal ''
          data[1].should.equal 'api'
          data[2].should.equal 'fake'
          data[3].should.equal 'thing'
          data[4].should.equal '1234'
          data[5].should.equal 'stuff'
          data[6].should.equal '5678'

      it 'single named param', ->
        Api = new @resource 'fake',
          custom:
            method: 'get'
            url: '/thing/:id'
        Api.custom({ id: 1234 }).then (data) ->
          data.should.have.length 5
          data[0].should.equal ''
          data[1].should.equal 'api'
          data[2].should.equal 'fake'
          data[3].should.equal 'thing'
          data[4].should.equal '1234'

      it 'multiple named params', ->
        Api = new @resource 'fake',
          custom:
            method: 'get'
            url: '/thing/:id/stuff/:name'
        Api.custom({ id: 1234, name: 5678 }).then (data) ->
          data.should.have.length 7
          data[0].should.equal ''
          data[1].should.equal 'api'
          data[2].should.equal 'fake'
          data[3].should.equal 'thing'
          data[4].should.equal '1234'
          data[5].should.equal 'stuff'
          data[6].should.equal '5678'

      it 'should honor EXACT prop', ->
        Api = new @resource 'API',
          custom:
            method: 'get'
            url: '/custom/url/?'
            exact: true
        Api.custom(1234).then (data) ->
          data.should.have.length 3
          data[0].should.equal 'custom'
          data[1].should.equal 'url'
          data[2].should.equal '1234'

      it 'bad args to wildcard params', ->
        Api = new @resource 'fake',
          custom:
            method: 'get'
            url: '/thing/?'
        Api.custom({ id: 1234 }).then (data) ->
          expect(data).to.be.null # we should never get here
        .catch (err) ->
          expect(err).to.be.instanceof Error

      it 'too few wildcard params', ->
        Api = new @resource 'fake',
          custom:
            method: 'get'
            url: '/thing/?/?'
        Api.custom(1234).then (data) ->
          expect(data).to.be.null # we should never get here
        .catch (err) ->
          expect(err).to.be.instanceof Error

      it 'bad args to named params', ->
        Api = new @resource 'fake',
          custom:
            method: 'get'
            url: '/thing/:id/stuff/:name'
        Api.custom(1234, 5678).then (data) ->
          expect(data).to.be.null # we should never get here
        .catch (err) ->
          expect(err).to.be.instanceof Error

      it 'too few named params', ->
        Api = new @resource 'fake',
          custom:
            method: 'get'
            url: '/thing/:id/:name'
        Api.custom({ id: 1234 }).then (data) ->
          expect(data).to.be.null # we should never get here
        .catch (err) ->
          expect(err).to.be.instanceof Error

      it 'mixed params in definition', ->
        try
          Api = new @resource 'fake',
            custom:
              method: 'get'
              url: '/thing/?/:name'
        catch ex
          expect(ex).to.be.instanceof Error

      it 'mixed params in other order', ->
        try
          Api = new @resource 'fake',
            custom:
              method: 'get'
              url: '/thing/:name/?'
        catch ex
          expect(ex).to.be.instanceof Error


    describe 'post', ->
      it 'should request to correct URL', ->
        Api = new @resource 'fake',
          custom:
            method: 'post'
            url: '/thing'
        Api.custom({ id: 1234 }).then (data) ->
          [slugs, body] = data
          slugs.should.have.length 4
          slugs[0].should.equal ''
          slugs[1].should.equal 'api'
          slugs[2].should.equal 'fake'
          slugs[3].should.equal 'thing'
          body.should.have.property 'id', 1234


    describe 'put', ->
      it 'should request to correct URL', ->
        Api = new @resource 'fake',
          custom:
            method: 'put'
            url: '/thing/:id'
        Api.custom({ id: 1234, body: 5678 }).then (data) ->
          [slugs, body] = data
          slugs.should.have.length 5
          slugs[0].should.equal ''
          slugs[1].should.equal 'api'
          slugs[2].should.equal 'fake'
          slugs[3].should.equal 'thing'
          slugs[4].should.equal '1234'
          body.should.have.property 'body', 5678

      it 'should handle separate BODY arg with wildcard', ->
        Api = new @resource 'fake',
          custom:
            method: 'put'
            strict: true
            url: '/thing/?'
        Api.custom(1234, { body: 5678 }).then (data) ->
          [slugs, body] = data
          slugs.should.have.length 5
          slugs[0].should.equal ''
          slugs[1].should.equal 'api'
          slugs[2].should.equal 'fake'
          slugs[3].should.equal 'thing'
          slugs[4].should.equal '1234'
          body.should.have.property 'body', 5678
