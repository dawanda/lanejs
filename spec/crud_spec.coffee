describe "Lib.Crud", ->

  beforeEach ->
    class @F extends Lib.Model
      @extend Lib.Crud
      @resource "foo"
      @endpoint "/bars/:bar_id/foos"
    for method in ["create", "read", "readAll", "update", "delete"]
      def = $.Deferred()
      sinon.stub( @F.Repo::, method ).returns( def )
      @F.Repo::[ method ].promise = def

  afterEach ->
    for method in ["create", "read", "readAll", "update", "delete"]
      @F.Repo::[ method ].calls?.reset()
      @F.Repo::[ method ].reset?()
      @F.Repo::[ method ].restore()
    delete @F

  describe "endpoint", ->
    it "initializes a repo for this class with the given path", ->
      probe = null
      class SpyRepo
        constructor: ( path ) ->
          probe = path
      class Foo extends Lib.Model
        @extend Lib.Crud
        @resource "foo"
        @Repo = SpyRepo
      Foo.endpoint "/foo"
      expect( probe ).toEqual "/foo"

  describe "find", ->
    it "calls read on the repo", ->
      @F.find( id: 123, bar_id: 321 )
      expect( @F.Repo::read.calledWith( id: 123, bar_id: 321 ) ).toBe true

    it "returns a promise for the model instance", ( done ) ->
      @F.find( id: 123, bar_id: 321 ).done ( foo ) ->
        expect( foo.toJSON() ).toEqual { id: 123, name: "Foo" }
        done()
      @F.Repo::read.promise.resolve( id: 123, name: "Foo" )

  describe "findAll", ->
    it "calls readAll on the repo", ->
      @F.findAll( bar_id: 123, xxx: "abc" )
      expect( @F.Repo::readAll.calledWith( bar_id: 123, xxx: "abc" ) ).toBe true

    it "returns a promise for the model instances", ( done ) ->
      @F.findAll( bar_id: 123 ).done ( foos ) ->
        expect( foos[0].toJSON() ).toEqual { id: 123, name: "Foo" }
        expect( foos[1].toJSON() ).toEqual { id: 321, name: "Bar" }
        done()
      @F.Repo::readAll.promise.resolve [{ id: 123, name: "Foo" }, { id: 321, name: "Bar" }]

  describe "create", ->
    it "calls create on the repo", ->
      @F.create( bar_id: 123 )
      expect( @F.Repo::create.calledWith( bar_id: 123 ) ).toBe true

    it "returns a promise for the model instance", ( done ) ->
      @F.create( id: 123, bar_id: 321 ).done ( foo ) ->
        expect( foo.toJSON() ).toEqual { id: 123, name: "Foo" }
        done()
      @F.Repo::create.promise.resolve { id: 123, name: "Foo" }

    it "fails if an invalid model is passed", ( done ) ->
      @F.create(
        isValid: -> false
      )
        .done -> throw "this should not succeed"
        .fail ( error ) ->
          expect( error ).toEqual "validationError"
          done()

  describe "update", ->
    it "calls update on the repo", ->
      @F.update( bar_id: 123, id: 5 )
      expect( @F.Repo::update.calledWith( bar_id: 123, id: 5 ) ).toBe true

    it "returns a promise", ->
      expect( @F.update( id: 123, bar_id: 321 ).then ).toEqual(jasmine.any(Function))

    it "fails if an invalid model is passed", ( done )->
      @F.update(
        isValid: -> false
      )
        .done -> throw "this should not succeed"
        .fail ( error ) ->
          expect( error ).toEqual "validationError"
          done()

  describe "delete", ->
    it "calls delete on the repo", ->
      @F.delete( bar_id: 123, id: 321 )
      expect( @F.Repo::delete.calledWith( bar_id: 123, id: 321 ) ).toBe true

    it "returns a promise", ->
      expect( @F.delete( id: 123, bar_id: 321 ).then ).toEqual(jasmine.any(Function))

describe "Lib.Crud.Repo", ->
  beforeEach ->
    @repo = new Lib.Crud.Repo("/bars/:bar_id/foos", "foo")
    @server = sinon.fakeServer.create()
    @lastRequest = =>
      @server.requests[ length - 1 ]
      length = @server.requests.length
      if length > 0
        @server.requests[ length - 1 ]
      else
        null
    @respondWith = ( data ) =>
      @lastRequest().respond 200, {'Content-Type': 'application/json'}, JSON.stringify(data)
    @failWith = ( status = 500 ) =>
      @lastRequest().respond status, {}, ""

  afterEach ->
    delete @respondWith
    delete @failWith
    delete @lastRequest
    @server.restore()

  describe "create", ->
    it "makes a POST request to the correct endpoint", ->
      @repo.create( bar_id: 321, xxx: "yyy" )
      expect( @lastRequest().method ).toEqual "POST"
      expect( @lastRequest().url ).toEqual "/bars/321/foos"
      expect( @lastRequest().requestBody ).toEqual encodeURI("foo[bar_id]=321&foo[xxx]=yyy")

  describe "read", ->
    it "makes a GET request to the correct endpoint", ->
      @repo.read( id: 123, bar_id: 321, xxx: "yyy" )
      expect( @lastRequest().method ).toEqual "GET"
      expect( @lastRequest().url ).toEqual "/bars/321/foos/123?xxx=yyy"

  describe "readAll", ->
    it "makes a GET request to the correct endpoint", ->
      @repo.readAll( bar_id: 123, xxx: "abc" )
      expect( @lastRequest().method ).toEqual "GET"
      expect( @lastRequest().url ).toEqual "/bars/123/foos?xxx=abc"

  describe "update", ->
    it "makes a PATCH request to the correct endpoint", ->
      @repo.update( id: 123, bar_id: 321, xxx: "yyy" )
      expect( @lastRequest().method ).toEqual "PATCH"
      expect( @lastRequest().url ).toEqual "/bars/321/foos/123"
      expect( @lastRequest().requestBody ).toEqual encodeURI("foo[id]=123&foo[bar_id]=321&foo[xxx]=yyy")

  describe "delete", ->
    it "makes a DELETE request to the correct endpoint", ->
      @repo.delete( id: 123, bar_id: 321, xxx: "yyy" )
      expect( @lastRequest().method ).toEqual "DELETE"
      expect( @lastRequest().url ).toEqual "/bars/321/foos/123"
      expect( @lastRequest().requestBody ).toEqual encodeURI("foo[id]=123&foo[bar_id]=321&foo[xxx]=yyy")

  describe "_ajax", ->
    it "returns a promise", ->
      expect( @repo._ajax( "GET", "/foo" ).then ).toEqual(jasmine.any(Function))

    it "normalize the success value of the returned promise", ( done ) ->
      @repo._ajax( "GET", "/foo" ).done ( data, otherStuff ) ->
        expect( data ).toEqual( abc: 123 )
        expect( typeof otherStuff ).toEqual("undefined")
        done()
      @respondWith( abc: 123 )

    it "normalize the failure value of the returned promise", ( done ) ->
      @repo._ajax( "GET", "/foo" ).fail ( error, otherStuff ) ->
        expect( error ).toEqual("error")
        expect( typeof otherStuff ).toEqual("undefined")
        done()
      @failWith( 503 )