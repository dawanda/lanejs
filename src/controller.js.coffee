namespace "Lib.Controller", ->

  # A Controller is the place for page-specific application logic. The actual
  # activation of the controller is done in a Router, but this is the place
  # where the actual code is situated. This class should be inherited by the
  # actual app controllers.
  #
  # You can do whatever you want here, including:
  #   - Instantiate models
  #   - Set up widgets
  #   - Make ajax calls
  #   - Activate jQuery plugins
  #
  # Look through the code of the Controller to find out more of what you can
  # do.
  #
  # Example:
  #
  #   class ProductsController extends Lib.Controller
  #     @beforeFilter "_loadHeader"
  #
  #     show: ->
  #       product = new Product(@params.id)
  #       new ProductWidget(product, '.widget')
  #       $.get('/track_product_visit')
  #
  class Controller extends Lib.Module

    # Private

    peek = ( array, idx = 1 ) ->
      array[ array.length - idx ]

    isArray = Array.isArray || ( maybe_array ) ->
      ({}).toString.call( maybe_array ) is "[object Array]"

    turnIntoArray = ( obj ) ->
      return [] unless obj?
      obj = [obj] if not isArray( obj )
      obj

    # Constructor

    constructor: ( request ) ->
      @_buildEnv(request)

    # Class methods

    @appendFilter: ( type, filters... ) ->
      opts = {}
      if typeof peek( filters ) is "object"
        opts = filters.pop()
      opts.only = turnIntoArray opts.only
      opts.except = turnIntoArray opts.except

      prop_name = "_#{type}_filters"
      @::[ prop_name ] ?= []
      unless @::hasOwnProperty prop_name
        @::[ prop_name ] = @::[ prop_name ][..]
      chain = @::[ prop_name ]

      for filter in filters
        item =
          fn: filter
        item[ key ] = val for key, val of opts
        chain.push item

    # Set up a method to be called before every action in the controller. Can
    # use "only" and "except" for deciding which actions to include/exclude.
    #
    # Example:
    #
    #   @beforeFilter 'requireUser', except: 'login'
    #   @beforeFilter 'loadProduct', only: 'show'
    #
    @beforeFilter: ( filters... ) ->
      @appendFilter "before", filters...

    # Set up a method to be called after every action in the controller. See
    # `beforeFilter` for more details.
    #
    @afterFilter: ( filters... ) ->
      @appendFilter "after", filters...

    @action: ( name ) ->
      Self = @
      ( args... ) ->
        instance = new Self args...
        instance._executeFiltersForAction name, "before"
        instance[ name ]()
        instance._executeFiltersForAction name, "after"

    @hasAction: ( name ) ->
      typeof @::[ name ] is "function"

    # Instance methods

    _buildEnv: ( request ) ->
      @request = request || {}
      @params  = @request.params || {}

    _executeFiltersForAction: ( action, type ) ->
      filters = @["_#{type}_filters"] || []
      for filter in filters
        if filter.only.length is 0 or action in filter.only
          if action not in filter.except
            fn = filter.fn
            fn = @[ fn ] if typeof fn is "string"
            fn.call @
