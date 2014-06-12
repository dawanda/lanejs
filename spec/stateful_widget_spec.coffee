describe "Lib.StatefulWidget", ->

  beforeEach ->
    @SW = Lib.StatefulWidget
    @el = $("<span id='stateful_widget'>")
    $("body").append @el

  afterEach ->
    @el.remove()
    delete @SW
    delete @el

  it "has Submachine class and instance methods", ->
    expect( @SW.hasStates ).toEqual(jasmine.any(Function))
    expect( @SW::switchTo ).toEqual(jasmine.any(Function))

  it "has EventSpitter instance methods", ->
    expect( @SW::on ).toEqual(jasmine.any(Function))
    expect( @SW::off ).toEqual(jasmine.any(Function))

  describe "constructor", ->

    it "takes a selector and sets the '$el' property to the corresponding jQuery selection object", ->
      sw = new @SW "#stateful_widget"
      expect( sw.$el.attr "id" ).toEqual "stateful_widget"

    it "takes a selector and sets the 'el' property to the corresponding DOM element", ->
      sw = new @SW "#stateful_widget"
      expect( sw.el ).toBe @el[0]

    it "initializes the state to the first one, if existing", ->
      @SW.hasStates "foo", "bar"
      sw = new @SW "#stateful_widget"
      expect( sw.state ).toEqual "foo"

    it "generates a unique id and set _uid", ->
      sw1 = new @SW "#stateful_widget"
      expect( sw1._uid ).toBeDefined()
      sw2 = new @SW "#stateful_widget"
      expect( sw1._uid isnt sw2._uid ).toBe(true)

    it "binds to all events specified in the event map, namespacing with _uid", ->
      spyOn $::, "on"
      fn1 = ->
      fn2 = ->
      spyOn(@SW::, "_boundInstanceMethod").and.callFake ( name ) ->
        fn2 if name is "foo"
      @SW::_event_map = [
        { event: "click", fn: fn1 },
        { event: "mouseover", target: ".baz", fn: "foo" }
      ]
      @SW::foo = ->
      sw = new @SW "#stateful_widget"
      expect( sw.$el.on ).toHaveBeenCalledWith "click.#{sw._uid}", fn1
      expect( sw.$el.on ).toHaveBeenCalledWith "mouseover.#{sw._uid}", ".baz", fn2

  describe "mapEvent", ->

    it "adds an item to the event map", ->
      @SW.mapEvent "click", "foo"
      expect( @SW::_event_map.pop() ).toEqual
        event: "click",
        fn:    "foo"

    it "does not change the superclass event map when calling it on a subclass", ->
      @SW.mapEvent "click", "foo"
      class Sub extends @SW
        @mapEvent "mouseover", "bar"
      expect( @SW::_event_map.pop() ).toEqual
        event: "click",
        fn:    "foo"

    it "sets the target property in the event map object if provided", ->
      @SW.mapEvent "click .foo", "foo"
      expect( @SW::_event_map.pop() ).toEqual
        event:  "click",
        target: ".foo",
        fn:     "foo"

  describe "mapEvents", ->

    it "maps all the specified events", ->
      spyOn @SW, "mapEvent"
      @SW.mapEvents
        click: "foo"
        "mouseover .bar": "baz"
      expect( @SW.mapEvent ).toHaveBeenCalledWith "click", "foo"
      expect( @SW.mapEvent ).toHaveBeenCalledWith "mouseover .bar", "baz"

  describe "instance methods", ->

    describe "unbind", ->

      it "unbinds all DOM events on this.$el namespaced under this._uid", ->
        spy = jasmine.createSpy()
        @SW.mapEvents
          "click": spy
        sw = new @SW "#stateful_widget"
        sw.unbind()
        @el.click()
        expect( spy ).not.toHaveBeenCalled()

      it "unbinds all non-DOM event listeners subscribing to this instance", ->
        spy = jasmine.createSpy()
        sw = new @SW "#stateful_widget"
        sw.on "foo", spy
        sw.unbind()
        sw.emit "foo"
        expect( spy ).not.toHaveBeenCalled()

  describe "any instance", ->

    beforeEach ->
      @SW.hasStates "foo", "bar"
      @sw = new @SW "#stateful_widget"

    afterEach ->
      delete @sw

    it "sets an html class reflecting the state", ->
      expect( @sw.$el.hasClass "foo" ).toBe(true)
      @sw.switchTo "bar"
      expect( @sw.$el.hasClass "bar" ).toBe(true)
      expect( @sw.$el.hasClass "foo" ).toBe(false)

    it "triggers a leaveState:<state> event whenever it leaves a state", ->
      spy = jasmine.createSpy()
      @sw.on "leaveState:foo", spy
      @sw.switchTo "bar"
      expect( spy ).toHaveBeenCalled()

    it "triggers an enterState:<state> event whenever it enters a state", ->
      spy = jasmine.createSpy()
      @sw.on "enterState:bar", spy
      @sw.switchTo "bar"
      expect( spy ).toHaveBeenCalled()
