#= require validators

namespace "Lib.Model", ->

  # A Model is an abstraction over a business model, a data container with
  # logic. It provides:
  #
  #   - attribute setters and getters
  #   - validations
  #   - serialization as JSON
  #   - events
  #
  # It's expected that this class will be extended.
  #
  # It's a good idea to listen to changes in the model and trigger UI events
  # based on those changes.
  #
  # See LoudAccessors: https://github.com/lucaong/loud-accessors
  # See validators:    lib/assets/javascripts/validators.js.coffee
  #
  # Example:
  #
  #   class Product extends Lib.Model
  #     @attrAccessible 'title', 'description', 'price'
  #
  #     @validatesPresenceOf 'title'
  #     @validatesPresenceOf 'price'
  #
  #     formattedPrice: -> '$' + @get('price')
  #
  #   product = new Product(title: 'Dress', price: 21.99)
  #   product.on 'change:price', (event, attribute, value) ->
  #     alert("New price! #{value}")
  #
  class Model extends Lib.Module

    @include LoudAccessors::

    constructor: ( attrs ) ->
      @set name, value, { clean: true } for name, value of attrs
      @emit "initialized", attrs

    # Class methods

    # Adds aribtrary validation object to the list of validations for
    # current class
    # @param validation - validator object to add
    @addValidation: ( validation ) ->
      # ensures that _validations is defined, default value is empty list
      @::_validations ?= []
      # ensures that current class has own _validations copy and its
      # modification will not touch any ancestor classess
      unless @::hasOwnProperty "_validations"
        @::_validations = @::_validations[..]
      # does the job - appends validation object to _validations
      @::_validations.push validation

    #=begin validates<Name>Of
    #
    # These validates<Name>Of all just delegate to validatesWith and
    # pass in built in validator class
    # @param attr - name of attribute to run validations on
    # @param opts - any options that builtin validator accept
    @validatesPresenceOf: ( attr, opts ) ->
      @validatesWith Lib.Validators.PresenceValidator, attr, opts

    @validatesFormatOf: ( attr, opts ) ->
      @validatesWith Lib.Validators.FormatValidator, attr, opts

    @validatesRangeOf: ( attr, opts ) ->
      @validatesWith Lib.Validators.RangeValidator, attr, opts

    @validatesAcceptanceOf: ( attr, opts ) ->
      @validatesWith Lib.Validators.AcceptanceValidator, attr, opts

    @validatesServerSideOf: ( attr, opts ) ->
      @validatesWith Lib.Validators.ServerSideValidator, attr, opts

    @validatesConfirmationOf: ( attr, opts ) ->
      @validatesWith Lib.Validators.ConfirmationValidator, attr, opts
    #=end validates<Name>Of

    # DSL-ish way to add builtin validators to model
    # @param attr - name of attribute to run validations on
    # @param validations - hash map where key is the <name> of builtin
    # validator and value is its options
    # Makes such DSL possible:
    #
    # ```coffee
    #   @validates "email",
    #     presence: true
    #     format:
    #       with: /put_your_email_regex_here/
    #       message: I18n.t("errors.users.email.invalid_format")
    # ```
    @validates: ( attr, validations ) ->
      # type - lowercased builtin validator name, opts - its options
      for type, opts of validations
        # capitalizes type
        capitalized = type.charAt(0).toUpperCase() + type[1..]
        # delegates to corresponding validates<Name>Of method
        @["validates#{capitalized}Of"] attr, opts

    # Instantiates object of Validator class passing all other
    # arguments to its constructor and delegates to addValidation
    # method passing this object in
    # @param Validator - builtin validator class
    # @param args... - other arguments to pass to constructor of Validator
    @validatesWith: ( Validator, args... ) ->
      @addValidation new Validator args...

    @attrAccessible: ( attrs... ) ->
      @::_attr_accessible ?= []
      unless @::hasOwnProperty "_attr_accessible"
        @::_attr_accessible = @::_attr_accessible[..]
      for attr in attrs
        @::_attr_accessible.push attr if attr not in @::_attr_accessible

    # Instance methods

    # Runs all validators
    # @param opts - options:
    #   - option silent - will not emit any events if it is true, but
    #     still will append any errors to @errors
    validate: ( opts ) ->
      @errors   = {}
      results   = []
      silent    = opts? and opts.silent
      # create new Future
      dfd       = new $.Deferred
      @emit "validate" unless silent
      # call all validators with validate method passing in current
      # model instance object
      for validation in @_validations || []
        results.push validation.validate(@)

      # wraps all validation.validate results in $() and registers
      # done callback on them. This is required for any validations
      # that return futures/promises - ie they are async
      # for normal results (non-async) callback gets called immediately
      $.when.apply($, results).done () =>
        # don't emit any validation errors if in silent mode
        unless silent
          # start with valid state
          valid = true
          # iterate over all kev-value pairs in @errors hash map
          for attr, errors of @errors
            # emit validation error
            @emit "invalid:#{attr}", errors
            # switch to invalid state
            valid = false
          # emit valid or invalid callback depending on resulting state
          @emit if valid then "valid" else "invalid"
        # mark future as finished
        dfd.resolve()

      # return future's promise
      dfd.promise()

    # Returns true if model instance object is valid, otherwise -
    # false
    # Should only be used when there is no
    # asynchronous validation
    # @param opts - options for validate method call
    isValid: ( opts ) ->
      # delegates to validate
      @validate opts
      # returns false if there were any errors
      for error of @errors
        return false
      # returns true otherwise
      true

    isBlank: (attribute_names...) ->
      if attribute_names.length > 0
        attributes = {}
        for k, v of @_attributes when k in attribute_names
          attributes[k] = v
      else
        attributes = @_attributes

      for k, v of attributes
        return false if v? and v isnt ''

      true

    # Adds an error to @errors hash map
    # @param name - attribute name = key for @errors hash map
    # @param message - error message = value for @errors hash map
    addError: ( name, message ) ->
      # initializes @errors with empty hash map if it is not defined
      @errors ?= {}
      # initializes errors entry for attribute with empty list if it is not defined
      @errors[ name ] ?= []
      # appends error message for attribute
      @errors[ name ].push message

    # Adds a base error to @errors hash map
    # Delegates to addError with attribute name = _base_
    # Usually _base_ error means that validation failed for whole
    # object and it is not particularly related to any attribute
    addErrorToBase: ( message ) ->
      @addError "_base_", message

    toJSON: ->
      to_json = {}
      for key, value of @_attributes
        value = value.toJSON() if value?.toJSON?
        to_json[ key ] = value
      to_json

    reset: ( attribute ) ->
      @untouch attribute
      @set attribute, null

    touch: ( attribute ) ->
      @touched ?= {}
      @touched[attribute] = true
      @emit "touched:#{attribute}", attribute

    untouch: ( attribute ) ->
      @touched ?= {}
      @touched[attribute] = false
      @emit "untouched:#{attribute}", attribute

    isTouched: ( attribute ) ->
      @touched ?= {}
      !!@touched[attribute]
