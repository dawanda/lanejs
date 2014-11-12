describe "Lib.Validators", ->

  beforeEach ->
    @V = Lib.Validators
    @model =
      addError: ->
      get: ->

  afterEach ->
    delete @V
    delete @model

  describe "BaseValidator", ->

    beforeEach ->
      spy = jasmine.createSpy()
      @MyValidator = class MyValidator extends @V.BaseValidator
        run: spy

    afterEach ->
      delete @MyValidator

    it "runs validations if no 'if' options is specified", ->
      v = new @MyValidator "foo"
      v.validate @model
      expect( v.run ).toHaveBeenCalledWith( @model )

    it "runs validations when the 'if' option evaluates to true", ->
      v = new @MyValidator "foo", if: -> true
      v.validate @model
      expect( v.run ).toHaveBeenCalledWith( @model )

    it "does not run validations when the 'if' option evaluates to something not true", ->
      v = new @MyValidator "foo", if: -> null
      v.validate @model
      expect( v.run ).not.toHaveBeenCalledWith( @model )

    it "evaluates the 'if' option in the scope of the validated object", ->
      receiver = null
      v = new @MyValidator "foo", if: -> receiver = @
      v.validate @model
      expect( receiver ).toBe( @model )

    it "when 'if' option is a string evaluates the method with that name", ->
      @model.bar = jasmine.createSpy()
      v = new @MyValidator "foo", if: "bar"
      v.validate @model
      expect( @model.bar ).toHaveBeenCalled()

  describe "PresenceValidator", ->

    it "adds no errors if the attribute is present", ->
      pv = new @V.PresenceValidator "foo"
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        return 123 if attr is "foo"
      pv.validate @model
      expect( @model.addError ).not.toHaveBeenCalled()

    it "adds a validation that adds an error if the attribute is not present", ->
      pv = new @V.PresenceValidator "foo"
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        return null
      pv.validate @model
      expect( @model.addError ).toHaveBeenCalledWith "foo", "empty"

    it "uses the specified message, if given", ->
      pv = new @V.PresenceValidator "foo", message: "missing foo"
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        return null
      pv.validate @model
      expect( @model.addError ).toHaveBeenCalledWith "foo", "missing foo"

  describe "FormatValidator", ->

    it "adds a validation that adds no errors if the attribute is not present", ->
      fv = new @V.FormatValidator "foo"
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
      fv.validate @model
      expect( @model.addError ).not.toHaveBeenCalled()

    it "adds a validation that adds no errors if the attribute is empty", ->
      fv = new @V.FormatValidator "foo"
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) -> ""
      fv.validate @model
      expect( @model.addError ).not.toHaveBeenCalled()

    it "adds a validation that adds no errors if the attribute matches format", ->
      fv = new @V.FormatValidator "foo", with: /abc/
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        "abcd"
      fv.validate @model
      expect( @model.addError ).not.toHaveBeenCalled()

    it "adds a validation that adds an error if the attribute does not match format", ->
      fv = new @V.FormatValidator "foo", with: /abc/
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        "xxx"
      fv.validate @model
      expect( @model.addError ).toHaveBeenCalledWith "foo", "invalid"

    it "uses the specified message, if given", ->
      fv = new @V.FormatValidator "foo", with: /abc/, message: "foo is crappy"
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        "xxx"
      fv.validate @model
      expect( @model.addError ).toHaveBeenCalledWith "foo", "foo is crappy"

  describe "RangeValidator", ->

    it "adds a validation that adds no errors if the attribute is not present", ->
      fv = new @V.RangeValidator "foo"
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
      fv.validate @model
      expect( @model.addError ).not.toHaveBeenCalled()

    it "adds a validation that adds no errors if the attribute is empty", ->
      fv = new @V.RangeValidator "foo"
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) -> ""
      fv.validate @model
      expect( @model.addError ).not.toHaveBeenCalled()

    it "adds a validation that adds no errors if the attribute is in the range", ->
      fv = new @V.RangeValidator "foo", min: 2, max: 9
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        5
      fv.validate @model
      expect( @model.addError ).not.toHaveBeenCalled()

    it "adds a validation that adds no errors if the attribute bigger or equal than the minimum", ->
      fv = new @V.RangeValidator "foo", min: 2
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        12
      fv.validate @model
      expect( @model.addError ).not.toHaveBeenCalled()

    it "adds a validation that adds no errors if the attribute lower or equal than the maximum", ->
      fv = new @V.RangeValidator "foo", max: 12
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        12
      fv.validate @model
      expect( @model.addError ).not.toHaveBeenCalled()

    it "adds a validation that adds an error if the attribute is not in the range", ->
      fv = new @V.RangeValidator "foo", min: 2, max: 9
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        1
      fv.validate @model
      expect( @model.addError ).toHaveBeenCalledWith "foo", "not in_range"

    it "adds a validation that adds an error if the attribute is lower than the minimum", ->
      fv = new @V.RangeValidator "foo", min: 2
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        1
      fv.validate @model
      expect( @model.addError ).toHaveBeenCalledWith "foo", "not in_range"

    it "adds a validation that adds an error if the attribute is bigger than the maximum", ->
      fv = new @V.RangeValidator "foo", max: 8
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        9
      fv.validate @model
      expect( @model.addError ).toHaveBeenCalledWith "foo", "not in_range"

  describe "AcceptanceValidator", ->

    it "adds no errors if the attribute has the acceptance value", ->
      pv = new @V.AcceptanceValidator "foo"
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        return "1" if attr is "foo"
      pv.validate @model
      expect( @model.addError ).not.toHaveBeenCalled()

    it "adds a validation that adds an error if the attribute has not the acceptance value", ->
      pv = new @V.AcceptanceValidator "foo"
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        return "2"
      pv.validate @model
      expect( @model.addError ).toHaveBeenCalledWith "foo", "accepted"

    it "uses the specified message, if given", ->
      pv = new @V.AcceptanceValidator "foo", message: "please accept foo"
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        return null
      pv.validate @model
      expect( @model.addError ).toHaveBeenCalledWith "foo", "please accept foo"

    it "uses the specified acceptance value, if given", ->
      pv = new @V.AcceptanceValidator "foo", accept: "yes"
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        return "yes" if attr is "foo"
      pv.validate @model
      expect( @model.addError ).not.toHaveBeenCalled()

  describe "LengthValidator", ->

    it "adds a validation that adds no errors if the attribute is not present", ->
      fv = new @V.LengthValidator "foo"
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
      fv.validate @model
      expect( @model.addError ).not.toHaveBeenCalled()

    it "adds a validation that adds no errors if the attribute is empty", ->
      fv = new @V.LengthValidator "foo"
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) -> ""
      fv.validate @model
      expect( @model.addError ).not.toHaveBeenCalled()

    it "adds a validation that adds an error if the attribute is longer than max", ->
      pv = new @V.LengthValidator "foo", max: 10
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        return "longer than ten characters"
      pv.validate @model
      expect( @model.addError ).toHaveBeenCalledWith "foo", "other"

    it "adds a validation that adds an error if the attribute is shorter than min", ->
      pv = new @V.LengthValidator "foo", min: 10
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        return "too short"
      pv.validate @model
      expect( @model.addError ).toHaveBeenCalledWith "foo", "other"

    it "adds a validation that adds an error if the attribute length is different then 'is'", ->
      pv = new @V.LengthValidator "foo", is: 10
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        return "not ten characters"
      pv.validate @model
      expect( @model.addError ).toHaveBeenCalledWith "foo", "other"

    it "adds a validation that adds no error if the attribute length is within boundaries", ->
      pv = new @V.LengthValidator "foo", min: 5, max: 20, is: 13
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        return "13 characters"
      pv.validate @model
      expect( @model.addError ).not.toHaveBeenCalled()

  describe "ConfirmationValidator", ->

    it "adds a validation that adds no errors if the attribute is not present", ->
      v = new @V.ConfirmationValidator "foo"
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) -> if attr is "foo" then undefined else "something"
      v.validate @model
      expect( @model.addError ).not.toHaveBeenCalled()

    it "adds a validation that adds no errors if the attribute is empty", ->
      v = new @V.ConfirmationValidator "foo"
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) -> if attr is "foo" then "" else "something"
      v.validate @model
      expect( @model.addError ).not.toHaveBeenCalled()

    it "adds a validation that adds an error if the attribute is different from confirmation", ->
      v = new @V.ConfirmationValidator "foo"
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        if attr is "foo"
          "something"
        else if attr is "foo_confirmation"
          "something else"
        else null
      v.validate @model
      expect( @model.addError ).toHaveBeenCalledWith "foo_confirmation", "confirmed"

    it "adds a validation that adds no error if the attribute is confirmed", ->
      v = new @V.ConfirmationValidator "foo"
      spyOn @model, "addError"
      spyOn(@model, "get").and.callFake ( attr ) ->
        if attr is "foo" or attr is "foo_confirmation"
          "something"
        else null
      v.validate @model
      expect( @model.addError ).not.toHaveBeenCalled()
