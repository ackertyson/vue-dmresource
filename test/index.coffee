chai = require 'chai'
expect = chai.expect
should = chai.should()

global.window = { Vue: { use: -> } }
resource = require '../src'

describe 'constructor', ->
  before ->

  it 'should set name and default URL', ->
    Api = new resource 'API'
    Api.name.should.equal 'API'
    Api.base_url.should.equal '/api/'

  it 'should honor provided URL', ->
    Api = new resource 'API', base: { url: '/different/path/' }
    Api.base_url.should.equal '/different/path/'

  it 'should create custom handler', ->
    Api = new resource 'API',
      custom:
        method: 'get'
        url: '/custom/url'
    expect(Api.custom).to.be.a.function
