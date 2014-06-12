describe "Lib.Controller", ->

  peek = ( array, idx = 1 ) ->
    array[ array.length - idx ]

  beforeEach ->
    @C = Lib.Controller

  afterEach ->
    delete @C::
    delete @C

  describe "class methods", ->

    describe "appendFilter", ->

      it "can accept one or more functions or strings, and pushes each of them in the right chain", ->
        fn1 = ->
        fn2 = "funk"
        fn3 = ->
        @C.appendFilter "foo", fn1, fn2, fn3, { foo: "bar" }
        expect( @C::_foo_filters.pop().fn ).toBe fn3
        expect( @C::_foo_filters.pop().fn ).toBe fn2
        expect( @C::_foo_filters.pop().fn ).toBe fn1

      it "does not change superclass' filters when extending it", ->
        fn = ->
        @C.appendFilter "foo", fn
        class Sub extends @C
          @appendFilter "foo", ->
        expect( @C::_foo_filters.pop().fn ).toBe fn

      describe "when 'only' or 'except' options are passed as the last argument", ->

        it "turns these options into arrays and stores them in each filter", ->
          fn1 = ->
          fn2 = ->
          @C.appendFilter "foo", fn1, fn2,
            only: ["foo", "bar"]
            except: "baz"
          expect( @C::_foo_filters.pop() ).toEqual
            fn: fn2
            only: ["foo", "bar"]
            except: ["baz"]
          expect( @C::_foo_filters.pop() ).toEqual
            fn: fn1
            only: ["foo", "bar"]
            except: ["baz"]

    describe "beforeFilter", ->

      it "calls appendFilter with the right arguments", ->
        spyOn @C, "appendFilter"
        @C.beforeFilter "foo", "bar"
        expect( @C.appendFilter ).toHaveBeenCalledWith "before", "foo", "bar"

    describe "afterFilter", ->

      it "calls appendFilter with the right arguments", ->
        spyOn @C, "appendFilter"
        @C.afterFilter "foo", "bar"
        expect( @C.appendFilter ).toHaveBeenCalledWith "after", "foo", "bar"

    describe "hasAction", ->

      beforeEach ->
        @C::foo = ->
        @C::not_a_function = "not a function"

      it "returns true if action is available", ->
        expect( @C.hasAction "foo" ).toBe(true)

      it "returns false if action is not available", ->
        expect( @C.hasAction "bar" ).toBe(false)

      it "returns false if the prototype property with that name is not a function", ->
        expect( @C.hasAction "not_a_function" ).toBe(false)

    describe "action", ->

      describe "returns a function that", ->
      
        it "instantiates controller and sets up the environment", ->
          spyOn @C::, "_buildEnv"
          @C::foo = ->
          req = {}
          @C.action("foo") req
          expect( @C::_buildEnv ).toHaveBeenCalledWith req

        it "calls before filters, then the action, then after filters", ->
          list = []
          spyOn(@C::, "_executeFiltersForAction").and.callFake ( action, type ) ->
            list.push type
          @C::foo = ->
            list.push "action"
          @C.action("foo").call()
          expect( list ).toEqual [ "before", "action", "after" ]

  describe "instance methods", ->

    describe "_executeFiltersForAction", ->

      afterEach ->
        delete @C::_before_filters

      it "calls all filters in order", ->
        list = []
        fn1 = -> list.push 1
        fn2 = -> list.push 2
        fn3 = -> list.push 3
        @C::_before_filters = [
          { fn: fn1, only: [], except: [] }
          { fn: fn2, only: [], except: [] }
          { fn: fn3, only: [], except: [] }
        ]
        ( new @C )._executeFiltersForAction "foo", "before"
        expect( list ).toEqual [ 1, 2, 3 ]

      it "looks for the filter in the instance methods by name if it is a string", ->
        @C::_before_filters = [
          fn:     "bar"
          only:   []
          except: []
        ]
        b = new @C
        b.bar = jasmine.createSpy()
        b._executeFiltersForAction "foo", "before"
        expect( b.bar ).toHaveBeenCalled()

      it "skips filters for which the action is not in the 'only' option, if not empty", ->
        spy = jasmine.createSpy()
        @C::_before_filters = [
          { fn: spy, only: ["bar"], except: [] }
        ]
        ( new @C )._executeFiltersForAction "foo", "before"
        expect( spy ).not.toHaveBeenCalled()

      it "skips filters for which the action is excluded with the 'except' option", ->
        spy = jasmine.createSpy()
        @C::_before_filters = [
          { fn: spy, only: [], except: ["foo"] }
        ]
        ( new @C )._executeFiltersForAction "foo", "before"
        expect( spy ).not.toHaveBeenCalled()

    describe "_buildEnv", ->

      it "defines request and params properties", ->
        b = new @C
        b._buildEnv()
        expect( b.request ).toBeDefined()
        expect( b.params ).toBeDefined()

      it "assign the first argument as the value of the request property", ->
        b = new @C
        req = {}
        b._buildEnv req
        expect( b.request ).toBe req

      it "sets the params property to request.params", ->
        b = new @C
        req =
          params: {}
        b._buildEnv req
        expect( b.params ).toBe req.params