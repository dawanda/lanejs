describe "Lib.Router", ->

  beforeEach ->
    @router = new Lib.Router

  afterEach ->
    delete @router

  describe "match", ->

    it "passes the right resource name to resourceToController", ->
      spy = jasmine.createSpy()
      spyOn(@router, "resourceToController").and.callFake ->
        class FooController extends Lib.Controller
      @router.match "/foo", "foo#bar"
      expect( @router.resourceToController ).toHaveBeenCalledWith "foo"

    it "adds a route calling the right controller action", ->
      spy = jasmine.createSpy()
      spyOn(@router, "resourceToController").and.callFake ->
        action: ( action ) ->
          return spy if action is "bar"
      @router.match "/foo", "foo#bar"
      @router.route "/foo"
      expect( spy ).toHaveBeenCalled()

  describe "resourceToController", ->

    it "returns the right controller for a resource", ->
      ns =
        FooBarController: {}
      @router.controllers = ns
      expect( @router.resourceToController "foo_bar" ).toBe ns.FooBarController

    it "throws if no controller is found", ->
      ns = {}
      @router.controllers = ns
      expect( => @router.resourceToController "foo_bar" ).toThrow()

  describe "namespace", ->

    it "looks up controllers in namespaced modules", ->
      ns =
        Foo:
          BarController: {}
      @router.controllers = ns
      @router.namespace "/foo", ->
        expect( @resourceToController "bar" ).toBe ns.Foo.BarController

    it "adds URL scoping", ->
      spy = jasmine.createSpy()
      @router.namespace "/foo", ->
        @map "/bar", spy
      @router.route "/foo/bar"
      expect( spy ).toHaveBeenCalled()

  describe "scope", ->

    it "looks up controllers in root module", ->
      ns =
        BarController: {}
      @router.controllers = ns
      @router.scope "foo", ->
        expect( @resourceToController "bar" ).toBe ns.BarController

    it "adds URL scoping", ->
      spy = jasmine.createSpy()
      @router.scope "foo", ->
        @map "/bar", spy
      @router.route "foo/bar"
      expect( spy ).toHaveBeenCalled()

  describe "resources", ->

    it "correctly namespaces routes", ->
      spyOn(@router, "resourceToController").and.callFake ->
        {}
      spyOn @router, "scope"
      @router.resources "foo"
      expect( @router.scope ).toHaveBeenCalledWith("/foo", jasmine.any(Function))

    it "push the resource to the stack of current resources and pops it after function execution", ->
      spyOn(@router, "resourceToController").and.callFake ->
        class FooController extends Lib.Controller
      @router.resources "foo", ->
        expect( @_resource_stack[ @_resource_stack.length - 1 ] ).toEqual( name: "foo", opts: {} )
      expect( @router._resource_stack.length ).toEqual 0

    it "maps all the standard routes, if corresponding controller methods exist", ->
      spyOn @router, "match"
      spyOn(@router, "resourceToController").and.callFake ->
        class FooController extends Lib.Controller
          index: ->
          show: ->
          new: ->
          edit: ->
      @router.resources "foo"
      expect( @router.match ).toHaveBeenCalledWith "", "foo#index"
      expect( @router.match ).toHaveBeenCalledWith "/:id", "foo#show"
      expect( @router.match ).toHaveBeenCalledWith "/new", "foo#new"
      expect( @router.match ).toHaveBeenCalledWith "/:id/edit", "foo#edit"

    it "does not map route to actions for which no corresponding controller method exists", ->
      spyOn @router, "match"
      spyOn(@router, "resourceToController").and.callFake ->
        class FooController extends Lib.Controller
          show: ->
          edit: ->
      @router.resources "foo"
      expect( @router.match ).not.toHaveBeenCalledWith("", "foo#index")
      expect( @router.match ).toHaveBeenCalledWith "/:id", "foo#show"
      expect( @router.match ).not.toHaveBeenCalledWith("/new", "foo#new")
      expect( @router.match ).toHaveBeenCalledWith "/:id/edit", "foo#edit"

    it "makes it possible to nest resources", ->
      spyOn(@router, "resourceToController").and.callFake (res) ->
        if res is "foo"
          class FooController extends Lib.Controller
            show: ->
        else if res is "bar"
          class BarController extends Lib.Controller
            show: ->
        else
          class BazController extends Lib.Controller
            new: ->
      @router.resources "foo", ->
        @resources "bar", ->
          @resources "baz"

      expect( @router.mappings.pop().route ).toEqual "/foo/:id"
      expect( @router.mappings.pop().route ).toEqual "/foo/:foo_id/bar/:id"
      expect( @router.mappings.pop().route ).toEqual "/foo/:foo_id/bar/:bar_id/baz/new"

    it "makes it possible to specify a particular controller", ->
      spyOn @router, "match"
      spyOn(@router, "resourceToController").and.callFake (res) ->
        if res is "foo"
          class FooController extends Lib.Controller
            show: ->
        else if res is "bar"
          class BarController extends Lib.Controller
            show: ->
      @router.resources "foo", { controller: "bar" }
      expect( @router.match ).toHaveBeenCalledWith "/:id", "bar#show"
      expect( @router.match ).not.toHaveBeenCalledWith("/:id", "foo#show")

    describe "when called with option `singular: true`", ->

      it "maps all the standard singular routes, if corresponding controller methods exist", ->
        spyOn @router, "match"
        spyOn(@router, "resourceToController").and.callFake ->
          class FooController extends Lib.Controller
            show: ->
            new: ->
            edit: ->
        @router.resources "foo", singular: true
        expect( @router.match ).toHaveBeenCalledWith "", "foo#show"
        expect( @router.match ).toHaveBeenCalledWith "/new", "foo#new"
        expect( @router.match ).toHaveBeenCalledWith "/edit", "foo#edit"

  describe "member", ->

    it "throws if there is no current resource", ->
      expect( => @router.member "bar" ).toThrow()

    it "adds new member routes for the current resource", ->
      spyOn(@router, "resourceToController").and.callFake ->
        class FooController extends Lib.Controller
          bar: ->
      @router._resource_stack = ["foo"]
      @router._prefix_stack = ["/foo"]
      @router.member "bar"
      expect( @router.mappings.pop().route ).toEqual "/foo/:id/bar"

    it "can also accept an array", ->
      spyOn(@router, "resourceToController").and.callFake ->
        class FooController extends Lib.Controller
          bar: ->
          baz: ->
      @router._resource_stack = ["foo"]
      @router._prefix_stack = ["/foo"]
      @router.member ["bar", "baz"]
      expect( @router.mappings.pop().route ).toEqual "/foo/:id/baz"
      expect( @router.mappings.pop().route ).toEqual "/foo/:id/bar"

  describe "collection", ->

    it "throws if there is no current resource", ->
      expect( => @router.collection "bar" ).toThrow()

    it "adds new collection routes for the current resource", ->
      spyOn(@router, "resourceToController").and.callFake ->
        class FooController extends Lib.Controller
          bar: ->
      @router._resource_stack = ["foo"]
      @router._prefix_stack = ["/foo"]
      @router.collection "bar"
      expect( @router.mappings.pop().route ).toEqual "/foo/bar"

    it "can also accept an array", ->
      spyOn(@router, "resourceToController").and.callFake ->
        class FooController extends Lib.Controller
          bar: ->
          baz: ->
      @router._resource_stack = ["foo"]
      @router._prefix_stack = ["/foo"]
      @router.collection ["bar", "baz"]
      expect( @router.mappings.pop().route ).toEqual "/foo/baz"
      expect( @router.mappings.pop().route ).toEqual "/foo/bar"

  describe "resource", ->

    it "proxies to `resources` with option `singular: true`", ->
      spyOn @router, "resources"
      fn = ->
      @router.resource "foo"
      expect( @router.resources ).toHaveBeenCalledWith "foo", { singular: true }, undefined
      @router.resource "foo", { bar: "baz" }
      expect( @router.resources ).toHaveBeenCalledWith "foo", { singular: true, bar: "baz" }, undefined
      @router.resource "foo", { bar: "baz" }, fn
      expect( @router.resources ).toHaveBeenCalledWith "foo", { singular: true, bar: "baz" }, fn
