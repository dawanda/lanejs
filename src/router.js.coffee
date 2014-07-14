#= require cartograph
#= require_self

namespace "Lib.Router", ->

  # The Router class provides a higher-level abstraction over Cartograph,
  # making use of convention to easily create routes for client side
  # controllers with a DSL very similar to Rails.
  #
  # Whenever a page request is hit, the router decides which javascript
  # controller to instantiate and which action to call. See Lib.Controller for
  # what happens afterwards.
  #
  # Example: see app/assets/javascripts/routes/routes.js.coffee
  #
  class Router extends Cartograph

    # Private

    camelize = ( str ) ->
      str.replace("/", "").replace /(?:^|[-_])(\w)/g, ( m, c ) ->
        ( c || "" ).toUpperCase()

    isArray = Array.isArray || ( maybe_array ) ->
      ({}).toString.call( maybe_array ) is "[object Array]"

    peek = ( array, idx = 1 ) ->
      array[ array.length - idx ]

    # Public

    constructor: ( args... ) ->
      @resource_routes =
        show: ""
        new:  "/new"
        edit: "/edit"
      @resources_routes =
        index: ""
        new:   "/new"
        show:  "/:id"
        edit:  "/:id/edit"
      @_resource_stack ?= []
      super( args... ) if super?

    lookupController: ( controller_name ) ->
      module        = @controllers or window
      module_stack  = @_module_stack || []
      for m in module_stack
        module = module[ m ]
      unless module[ controller_name ]?
        throw new Error "#{module_stack.join('.')}.#{ controller_name } is null or undefined"
      module[ controller_name ]

    resourceToController: ( resource ) ->
      controller_name = "#{ camelize resource }Controller"
      @lookupController( controller_name )

    match: ( path, action_str ) ->
      split = action_str.split "#"
      resource = split[0]
      action   = split[1]
      controller = @resourceToController resource
      @map path, controller.action( action )

    # For consistency with Rails, we call Cartograph's original `namespace`
    # method to `scope`, and we modify `namespace` to also influence the
    # controller lookup
    scope: Cartograph::namespace

    namespace: ( ns, fn ) ->
      @_module_stack   ?= []
      @_module_stack.push camelize( ns )
      try
        super ns, fn
      finally
        @_module_stack.pop()

    resources: ( name, opts = {}, fn ) ->
      if typeof opts is "function" and not fn?
        [ fn, opts ] = [ opts, {} ]

      controller_name = opts?.controller or name
      controller = @resourceToController controller_name
      outer_resource = peek @_resource_stack
      prefix = ""
      prefix = "/:#{outer_resource.name}_id" if outer_resource?

      @scope "#{prefix}/#{name}", ->
        @_resource_stack.push { name, opts }
        try
          fn.call @ if fn?
        finally
          @_resource_stack.pop()

        routes = if opts?.singular
          @resource_routes
        else
          @resources_routes
        # more specific routes for new needs to be generated first, otherwise /new
        # conflicts with /:id
        actions = ( [key, value] for own key, value of routes )
          .sort ( a, b ) ->
            a[1].replace(":id", "").length < b[1].replace(":id", "").length
          .map ( a ) -> a[0]
        for action in actions
          if controller.hasAction action
            @match routes[ action ], "#{controller_name}##{action}"

    resource: ( name, opts, fn ) ->
      if typeof opts is "function" and not fn?
        [ fn, opts ] = [ opts, {} ]

      opts ?= {}
      opts.singular = true
      @resources name, opts, fn

    addAction: ( action, route ) ->
      resource = peek @_resource_stack
      unless resource?
        throw new Error "no resource defined"
      controller_name = resource.opts?.controller or resource.name
      controller = @resourceToController controller_name
      if controller.hasAction( action )
        @match route, "#{controller_name}##{action}"

    member: ( action ) ->
      unless isArray action
        return @addAction action, "/:id/#{action}"
      @member a for a in action

    collection: ( action ) ->
      unless isArray action
        return @addAction action, "/#{action}"
      @collection a for a in action
