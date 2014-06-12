#= require request
#= require jquery
#= require url_builder

namespace "Lib.Navigator", ->

  # The Navigator manipulates the current url. The most important public method
  # is `navigate`. When given a url description, it updates the url and emits a
  # "navigate" event you can bind to in order to call some specific javascript.
  #
  # An instance of a `Router` could listen to an instance of the `Navigator` to
  # call the relevant `Controller` objects upon a client-side url change.
  #
  # Example:
  #
  #   navigator = new Navigator
  #   navigator.on 'navigate', (event, url, params) ->
  #     console.log(url)
  #
  #   navigator.navigate '/users/:id', {id: 123}
  #

  class Navigator extends Lib.Module

    _popped = false

    @include EventSpitter::

    constructor: ->
      $.event.props.push "state" unless "state" in $.event.props
      @_last_fragment = @getFragment()
      $( window ).on "popstate.navigator", ( evt ) =>
        @_popStateHandler( evt )

    navigate: ( fragment, params = {} ) ->
      fragment = @buildFragment fragment, params
      if fragment isnt @getFragment()
        @_pushState params, null, fragment
        unless @_refreshingPage
          @_last_fragment = fragment
          @emit "navigate", fragment, params

    # e.g.:
    # `buildFragment("/foo/:id", { id: 123, bar: "baz", qux: [1, 2] })`
    # would return `"/foo/123?bar=baz&qux[]=1&qux[]=2"`
    buildFragment: ( fragment, params = {} ) ->
      Lib.URLBuilder.buildURL( fragment, params )

    getFragment: ->
      # TODO make this better, like add support for hash-URLs
      # where pushState is not supported
      location.pathname + location.search

    _pushState: ( data = {}, title = null, url ) ->
      # for now, if pushState isn't available, reload page
      @_popped = true
      if @_hasPushState()
        history.pushState { _navigator: data }, title, url
      else
        @_pageRefresh url

    _popStateHandler: ( evt ) ->
      state = evt.state
      if state? and state._navigator?
        fragment = @getFragment()
        @_last_fragment = fragment
        @emit "navigate", fragment, state._navigator
      else if @_last_fragment isnt @getFragment()
        @_pageRefresh @getFragment() if @_popped
      @_popped = true

    _pageRefresh: ( url ) ->
      @_refreshingPage = true
      window.location  = url

    _hasPushState: ->
      history?.pushState?

    _isInitialPop: ->
      @_initial_pop

    _popped: _popped
