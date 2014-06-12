describe "Lib.Model", ->

  beforeEach ->
    @M = Lib.Model

  afterEach ->
    delete @M::
    delete @M

  describe "class methods", ->

    afterEach ->
      delete @M::_validations

    describe "addValidation", ->

      it "appends a validation to the list of validations", ->
        v = ->
        @M.addValidation v
        expect( @M::_validations.pop() ).toBe v

      it "does not modify validation on superclass when inheriting from a model", ->
        v = ->
        @M.addValidation v
        class Sub extends @M
          @addValidation ->
        expect( @M::_validations.pop() ).toBe v

    describe "validatesPresenceOf", ->

      it "validates with Lib.Validators.PresenceValidator", ->
        opts = message: "foo!!!"
        spyOn @M, "validatesWith"
        @M.validatesPresenceOf "foo", opts
        expect( @M.validatesWith ).toHaveBeenCalledWith Lib.Validators.PresenceValidator, "foo", opts

    describe "validatesFormatOf", ->

      it "validates with Lib.Validators.FormatValidator", ->
        opts = message: "foo!!!"
        spyOn @M, "validatesWith"
        @M.validatesFormatOf "foo", opts
        expect( @M.validatesWith ).toHaveBeenCalledWith Lib.Validators.FormatValidator, "foo", opts

    describe "validatesLengthOf", ->

      it "validates with Lib.Validators.LengthValidator", ->
        opts = message: "foo!!!"
        spyOn @M, "validatesWith"
        @M.validatesFormatOf "foo", opts
        expect( @M.validatesWith ).toHaveBeenCalledWith Lib.Validators.FormatValidator, "foo", opts

    describe "validatesRangeOf", ->

      it "validates with Lib.Validators.RangeValidator", ->
        opts = message: "foo!!!"
        spyOn @M, "validatesWith"
        @M.validatesRangeOf "foo", opts
        expect( @M.validatesWith ).toHaveBeenCalledWith Lib.Validators.RangeValidator, "foo", opts

    describe "validatesAcceptanceOf", ->

      it "validates with Lib.Validators.AcceptanceValidator", ->
        opts = message: "foo!!!"
        spyOn @M, "validatesWith"
        @M.validatesAcceptanceOf "foo", opts
        expect( @M.validatesWith ).toHaveBeenCalledWith Lib.Validators.AcceptanceValidator, "foo", opts

    describe "validates", ->

      it "delegates to the appropriate validation methods", ->
        opts = {}
        spy = jasmine.createSpy()
        class Foo extends @M
          @validatesQuuxOf: spy
          @validates "bar", quux: opts
        expect( spy ).toHaveBeenCalledWith "bar", opts

    describe "validatesWith", ->

      it "adds a validation using the supplied validator class", ->
        validator = ->
        class FakeValidator
          constructor: ->
            return validator
        class Foo extends @M
          @validatesWith FakeValidator
        expect( Foo::_validations.pop() ).toBe validator

      it "passes other args to the validator class constructor", ->
        spy = jasmine.createSpy()
        class FakeValidator
          constructor: spy
        class Foo extends @M
          @validatesWith FakeValidator, 123, "abc"
        expect( spy ).toHaveBeenCalledWith 123, "abc"

    describe "attrAccessible", ->

      beforeEach ->
        delete @M::_attr_accessible

      it "sets the list of accessible attributes", ->
        @M.attrAccessible "foo", "bar"
        expect( @M::_attr_accessible ).toEqual ["foo", "bar"]

      it "updates the existing list of accessible attributes", ->
        @M::._attr_accessible = ["foo", "bar"]
        @M.attrAccessible "foo", "baz"
        expect( @M::_attr_accessible ).toEqual ["foo", "bar", "baz"]

      it "does not change the list of accessible attributes on parent classes", ->
        @M::_attr_accessible = ["foo", "bar"]
        class Sub extends @M
          @attrAccessible "qux"
        expect( @M::_attr_accessible ).toEqual ["foo", "bar"]

  describe "instance methods", ->

    describe "validate", ->

      beforeEach ->
        delete @M::_validations
        @server = sinon.fakeServer.create()
        @respondWith = ( data, status = 200 ) ->
          last_request = @server.requests[ @server.requests.length - 1 ]
          last_request.respond status, {'Content-Type': 'application/json'}, JSON.stringify(data)

      afterEach ->
        delete @respondWith
        @server.restore()

      it "resets the errors property to an empty object", ->
        foo = new @M
        foo.validate()
        expect( foo.errors ).toEqual {}

      it "calls each validation passing self", ->
        v1 = validate: jasmine.createSpy()
        v2 = validate: jasmine.createSpy()
        @M::_validations = [v1, v2]
        foo = new @M
        foo.validate()
        expect( v1.validate ).toHaveBeenCalledWith foo
        expect( v2.validate ).toHaveBeenCalledWith foo

      it "emits a 'validate' event", ->
        foo = new @M
        spyOn foo, "emit"
        foo.validate()
        expect( foo.emit ).toHaveBeenCalledWith "validate"

      it "emits an 'invalid:<attribute>' event for every invalid attribute passing the errors", ->
        v = validate: ( obj ) -> obj.addError "bar", "!!!"
        @M::_validations = [ v ]
        foo = new @M
        spyOn foo, "emit"
        foo.validate()
        expect( foo.emit ).toHaveBeenCalledWith "invalid:bar", ["!!!"]

      it "emits a 'valid' event if model is valid", ->
        v = validate: ->
        @M::_validations = [ v ]
        foo = new @M
        spyOn foo, "emit"
        foo.validate()
        expect( foo.emit ).toHaveBeenCalledWith "valid"

      it "emits an 'invalid' event if model is invalid", ->
        v = validate: ( obj ) -> obj.addError "bar", "!!!"
        @M::_validations = [ v ]
        foo = new @M
        spyOn foo, "emit"
        foo.validate()
        expect( foo.emit ).toHaveBeenCalledWith "invalid"

      it "does not emit events if called with option silent: true", ->
        v = validate: ( obj ) -> obj.addError "baz", "???"
        @M::_validations = [ v ]
        foo = new @M
        spyOn foo, "emit"
        foo.validate silent: true
        expect( foo.emit ).not.toHaveBeenCalled()

    describe "isValid", ->

      it "performs validation passing the options", ->
        foo = new @M
        spyOn foo, "validate"
        foo.isValid foo: "bar"
        expect( foo.validate ).toHaveBeenCalledWith foo: "bar"

      it "returns false if there is any error", ->
        foo = new @M
        spyOn(foo, "validate").and.callFake ->
          @errors = foo: "bar"
        expect( foo.isValid() ).toBe(false)

      it "returns true if there is no error", ->
        foo = new @M
        spyOn(foo, "validate").and.callFake ->
          @errors = {}
        expect( foo.isValid() ).toBe(true)

    describe "addError", ->

      it "adds an error for an attribute", ->
        foo = new @M
        foo.addError "bar", "wrong!"
        expect( foo.errors.bar.pop() ).toBe "wrong!"

    describe "addErrorToBase", ->

      it "adds an error for the pseudo-attribute _base_", ->
        foo = new @M
        spyOn foo, "addError"
        foo.addErrorToBase "wrong!"
        expect( foo.addError ).toHaveBeenCalledWith "_base_", "wrong!"

    describe "toJSON", ->

      it "returns a (shallow) clone of the attributes", ->
        foo = new @M( name: "John", age: 25 )
        to_json = foo.toJSON()
        expect( to_json ).toEqual
          name: "John"
          age: 25
        to_json.name = "Tom"
        expect( foo.get "name" ).toEqual "John"

      it "calls toJSON method on attributes if defined", ->
        ageObj =
          toJSON: -> 25
        foo = new @M( age: ageObj )
        expect( foo.toJSON() ).toEqual
          age: 25

    describe "blank", ->

      it "returns true if all attributes are nully or empty strings", ->
        record = new @M( age: null, name: undefined, email: '' )
        expect( record.isBlank() ).toBe(true)

        record = new @M( age: 1, name: undefined, email: '' )
        expect( record.isBlank() ).toBe(false)

        record = new @M( age: null, name: 'Jim', email: '' )
        expect( record.isBlank() ).toBe(false)

      it "can be scoped only on the given attributes", ->
        record = new @M( age: null, name: 'Jim', email: '' )
        expect( record.isBlank('email', 'age') ).toBe(true)

        record = new @M( age: null, name: 'Jim', email: 'jim@example.com' )
        expect( record.isBlank('email', 'age') ).toBe(false)

  describe "constructor", ->

    it "sets the attributes", ->
      attrs = { name: "Wintermute" }
      foo = new @M( attrs )
      expect( foo.get "name" ).toEqual "Wintermute"

    it "emits an 'initialized' event", ->
      spyOn @M::, "emit"
      attrs = { foo: "bar" }
      foo = new @M( attrs )
      expect( @M::emit ).toHaveBeenCalledWith "initialized", attrs