describe "Lib.Persistable", ->

  beforeEach ->
    class @F extends Lib.Model
      @include Lib.Persistable::
    @foo = new @F(name: 'test', price: 100, colors: ['ffffff', '000000'])

  afterEach ->
    delete @F
    delete @foo

  describe "constructor", ->

    it "setups attributes", ->
      attrs = 
        name: 'test'
        price: 100
        colors: ['ffffff', '000000']

      @foo = new @F(attrs)
      expect( @foo._attributes ).toEqual attrs

  describe "persist", ->

    it "adds dirty attributes to attributes", ->
      @foo.set "name", "skirt"
      expect( @foo._attributes.name ).toEqual "test"
      @foo.persist()
      expect( @foo._attributes.name ).toEqual "skirt"
      expect( @foo.get "name" ).toEqual "skirt"

    it "emits an 'persisted' event", ->
      attrs = 
        name: 'test'
        price: 100
        colors: ['ffffff', '000000']

      @foo = new @F(attrs)
      @foo.set "name", "foo"
      spyOn @F::, "emit"
      @foo.persist()

      expect( @F::emit ).toHaveBeenCalledWith "persisted", { name: "foo" }

    it "does not emit an 'persisted' event when option is silent", ->
      attrs = 
        name: 'test'
        price: 100
        colors: ['ffffff', '000000']

      @foo = new @F(attrs)
      spyOn @F::, "emit"
      @foo.persist(silent: true)

      expect( @F::emit ).not.toHaveBeenCalledWith("persisted")

  describe "rollback", ->

    it "rolls back all attributed", ->
      attrs = 
        name: 'test'
        price: 100
        colors: ['ffffff', '000000']

      @foo = new @F(attrs)
      @foo.set "name", "foo"
      @foo.set "colors", ["eeeeee"]

      expect( @foo.get "name" ).toEqual "foo"
      expect( @foo.get "colors" ).toEqual ["eeeeee"]

      @foo.rollback()
      
      expect( @foo.get "name" ).toEqual "test"
      expect( @foo.get "colors" ).toEqual ['ffffff', '000000']

    it "emits an 'rolled back' event", ->
      spyOn @F::, "emit"

      attrs = 
        name: 'test'
        price: 100
        colors: ['ffffff', '000000']

      @foo = new @F(attrs)
      @foo.set "name", "foo"
      @foo.rollback()

      expect( @F::emit ).toHaveBeenCalledWith "rolled back", { name: 'foo' }

    it "emits 'change' event only for changed attributes", ->
      attrs = 
        name: 'test'
        price: 100
        colors: ['ffffff', '000000']

      @foo = new @F(attrs)
      @foo.set "name", "foo"
      spyOn @foo, "emit"
      @foo.rollback()

      expect( @foo.emit ).toHaveBeenCalledWith "change:name", "name", "test"
      expect( @foo.emit ).not.toHaveBeenCalledWith("change:price")

    it "does not emit 'change' and 'rolled back' event when option is silent true", ->
      attrs = 
        name: 'test'
        price: 100
        colors: ['ffffff', '000000']

      @foo = new @F(attrs)
      @foo.set "name", "foo"
      @foo.set "price", 100
      spyOn @foo, "emit"
      @foo.rollback(silent: true)

      expect( @foo.emit ).not.toHaveBeenCalledWith("change:name")
      expect( @foo.emit ).not.toHaveBeenCalledWith("change:price")
      expect( @foo.emit ).not.toHaveBeenCalledWith("rolled back")

  describe "changes", ->

    it "get a hash of dirty attributes", ->
      attrs = 
        name: 'test'
        price: 100
        colors: ['ffffff', '000000']

      @foo = new @F(attrs)
      @foo.set "name", "foo"
      @foo.set "price", 200

      expect( @foo.changes() ).toEqual { name: "foo", price: 200 }

    it "get an empty hash of dirty attributes", ->
      attrs = 
        name: 'test'
        price: 100
        colors: ['ffffff', '000000']

      @foo = new @F(attrs)
      @foo.set "name", "foo"
      @foo.set "name", "test"

      expect( @foo.changes() ).toEqual { }

    it "calls toJSON method on attributes if defined", ->
      priceObj =
        toJSON: -> 25
      @foo.set "price", priceObj
      expect( @foo.changes() ).toEqual
        price: 25

