#= require submachine
#= require eventspitter
#= require jquery

namespace "Lib.StatefulWidget", ->

  # The StatefulWidget provides an abstraction over DOM elements, much like a
  # Backbone view. The resulting object is eventful, you can listen and respond
  # to javascript events (for example, DOM events). It's also stateful and you
  # can provide specific behaviour and DOM styling for its states.
  #
  # To use it, make a new class that extends it.
  #
  # Example:
  #
  #   class MenuWidget extends Lib.StatefulWidget
  #     @hasStates 'active', 'inactive'
  #
  #     @transition from: 'inactive', to: 'active',   on: 'activate'
  #     @transition from: 'active',   to: 'inactive', on: 'deactivate'
  #
  #     @mapEvents
  #       mouseover: 'activate'
  #       mouseout:  'deactivate'
  #
  #     @onEnter 'active',   showTheMenu
  #     @onEnter 'inactive', hideTheMenu
  #
  #   menu = new MenuWidget('.menu')
  #
  #   menu.on 'enterState:active', ->
  #     Counter.increment 'userActivatedMenu'
  #
  # See:
  #
  #   Submachine:   https://github.com/lucaong/submachine
  #   EventSpitter: https://github.com/lucaong/eventspitter
  #
  class StatefulWidget extends Lib.Module

    @extendAndInclude Submachine
    @extendAndInclude EventSpitter

    @onEnter "*", ->
      @$el.addClass @state
      @emit "enterState:#{@state}"

    @onLeave "*", ->
      @$el.removeClass @state
      @emit "leaveState:#{@state}"

    constructor: ( selector ) ->
      @_uid ?= @_generateUID()
      @$el = $( selector )
      throw new Error "Unable to select DOM element with selector '#{selector}'" unless @$el.length
      @el = @$el[0]
      @initState @_states[0] if @_states?[0]?
      @_bindEvents()

    unbind: ->
      @$el.off ".#{@_uid}"
      @off()

    _bindEvents: ->
      return false unless @_event_map
      for item in @_event_map
        do ( item ) =>
          args = [ "#{item.event}.#{@_uid}" ]
          args.push item.target if item.target?
          if typeof item.fn is "string"
            args.push @_boundInstanceMethod( item.fn )
          else
            args.push item.fn
          @$el.on.apply @$el, args

    _boundInstanceMethod: ( name ) ->
      ( args... ) => @[ name ] args...

    _generateUID: ->
      StatefulWidget.nextUID()

    # Public class methods

    @nextUID: ->
      @_uid_counter ?= 0
      @_uid_counter += 1
      "widget_#{@_uid_counter}"

    @mapEvent: ( evt, fn ) ->
      @::_event_map ?= []
      unless @::hasOwnProperty "_event_map"
        @::_event_map = @::_event_map[..]
      [ str, evt, target ] = /([^\s]*)\s*(.*)/.exec evt
      map =
        event: evt
        fn:    fn
      map.target = target if target?.length > 0
      @::_event_map.push map

    @mapEvents: ( map ) ->
      @mapEvent evt, fn for evt, fn of map

    @events: @::mapEvents
