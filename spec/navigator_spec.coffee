describe "Lib.Navigator", ->

  beforeEach ->
    @Nav = Lib.Navigator
    @n = new @Nav
    spyOn @n, "_pageRefresh"

  afterEach ->
    $( window ).off ".navigator"
    delete @[v] for v in ["Nav", "n"]

  describe "buildFragment", ->

    it "adds querystring params", ->
      expect( @n.buildFragment "/foo", { bar: "baz", qux: 123 } ).toEqual "/foo?bar=baz&qux=123"

    it "correctly handle URLs that already have querystring params", ->
      expect( @n.buildFragment "/foo?abc", { bar: "baz", qux: 123 } ).toEqual "/foo?abc&bar=baz&qux=123"

    it "interpolates URL params", ->
      expect( @n.buildFragment "/foo/:bar/baz/:qux", { bar: "xxx", qux: 123, quux: 321 } ).toEqual "/foo/xxx/baz/123?quux=321"

    it "handles array params", ->
      expect( @n.buildFragment "/foo", { bar: ["baz",123] } ).toEqual "/foo?bar%5B%5D=baz&bar%5B%5D=123"

    it "does not add unnecessary leading '?'", ->
      expect( @n.buildFragment "/foo", {} ).toEqual "/foo"

  describe "constructor", ->

    it "binds on popstate", ->
      spyOn @n, "_popStateHandler"
      $( window ).trigger "popstate"
      expect( @n._popStateHandler ).toHaveBeenCalled()

  describe "navigate", ->

    it "builds path with data", ->
      spyOn @n, "_pushState"
      spyOn @n, "buildFragment"
      data = { baz: 123 }
      @n.navigate "/foo/bar", data
      expect( @n.buildFragment ).toHaveBeenCalledWith( "/foo/bar", data )

    it "calls _pushState with built path and data", ->
      spyOn @n, "_pushState"
      spyOn(@n, "buildFragment").and.callFake -> "/xyz"
      data = { baz: 123 }
      @n.navigate "/foo/bar", data
      expect( @n._pushState ).toHaveBeenCalledWith( data, null, "/xyz" )

    it "emits 'navigate' event passing built path and data", ->
      spyOn @n, "_pushState"
      spyOn(@n, "buildFragment").and.callFake -> "/xyz"
      spy = jasmine.createSpy()
      @n.on "navigate", spy
      data = { xxx: 123 }
      @n.navigate "/foo/bar", data
      expect( spy ).toHaveBeenCalledWith( "navigate", "/xyz", data )

  describe "_popStateHandler", ->

    it "emits 'navigate' event passing path and data", ->
      spyOn(@n, "getFragment").and.callFake -> "/xxx"
      spy = jasmine.createSpy()
      state = { _navigator: true }
      @n.on "navigate", spy
      @n._popStateHandler state: state
      expect( spy ).toHaveBeenCalledWith "navigate", "/xxx", state._navigator

    it "does not emit 'navigate' event if state is missing", ->
      spyOn(@n, "getFragment").and.callFake -> "/xxx"
      spy = jasmine.createSpy()
      @n.on "navigate", spy
      @n._popStateHandler {}
      expect( spy ).not.toHaveBeenCalled()

    it "does not emit 'navigate' event if state._navigator is not set", ->
      spyOn(@n, "getFragment").and.callFake -> "/xxx"
      spy = jasmine.createSpy()
      @n.on "navigate", spy
      @n._popStateHandler state: {}
      expect( spy ).not.toHaveBeenCalled()

    it "sets _popped to true", ->
      @n._popped = false
      @n._popStateHandler( state: {} )
      expect( @n._popped ).toBe(true)

  describe "_pushState", ->

    it "sets _popped to true", ->
      @n._popped = false
      spyOn(@n, "getFragment").and.callFake -> "/yyy"
      @n._pushState()
      expect( @n._popped ).toBe(true)