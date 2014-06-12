describe "Lib.Module", ->
  
  beforeEach ->
    @Mod = Lib.Module

  afterEach ->
    delete @Mod

  describe "extend", ->
 
    it "copies over class methods", ->
      @Mod.extend
        foo: 123
        bar: 321
      expect( @Mod ).toMatch
        foo: 123
        bar: 321
 
    it "calls extended callback if defined, passing the extended class", ->
      spy = jasmine.createSpy()
      @Mod.extend
        extended: spy
      expect( spy ).toHaveBeenCalledWith @Mod
 
    it "does not copy over 'extended' nor 'included' properties", ->
      @Mod.extend
        extended: ->
        included: ->
      expect( @Mod.extended ).not.toBeDefined()
      expect( @Mod.included ).not.toBeDefined()

  describe "include", ->
 
    it "copies over instance methods", ->
      @Mod.include
        foo: 123
        bar: 321
      expect( @Mod:: ).toMatch
        foo: 123
        bar: 321
 
    it "calls included callback if defined, passing the including class", ->
      spy = jasmine.createSpy()
      @Mod.include
        included: spy
      expect( spy ).toHaveBeenCalledWith @Mod

  describe "extendAndInclude", ->

    it "throws error if the argument has no prototype", ->
      expect( => @Mod.extendAndInclude {} ).toThrow()

    it "extends the given class", ->
      spyOn @Mod, "extend"
      class Klass
      @Mod.extendAndInclude Klass
      expect( @Mod.extend ).toHaveBeenCalledWith Klass

    it "includes the given class' prototype", ->
      spyOn @Mod, "include"
      class Klass
      @Mod.extendAndInclude Klass
      expect( @Mod.include ).toHaveBeenCalledWith Klass::