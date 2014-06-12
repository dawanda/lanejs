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

    @addValidation: ( validation ) ->
      @::_validations ?= []
      unless @::hasOwnProperty "_validations"
        @::_validations = @::_validations[..]
      @::_validations.push validation

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

    @validates: ( attr, validations ) ->
      for type, opts of validations
        capitalized = type.charAt(0).toUpperCase() + type[1..]
        @["validates#{capitalized}Of"] attr, opts

    @validatesWith: ( Validator, args... ) ->
      @addValidation new Validator args...

    @attrAccessible: ( attrs... ) ->
      @::_attr_accessible ?= []
      unless @::hasOwnProperty "_attr_accessible"
        @::_attr_accessible = @::_attr_accessible[..]
      for attr in attrs
        @::_attr_accessible.push attr if attr not in @::_attr_accessible

    # Instance methods

    validate: ( opts ) ->
      @errors   = {}
      results   = []
      silent    = opts? and opts.silent
      dfd       = new $.Deferred
      @emit "validate" unless silent
      for validation in @_validations || []
        results.push validation.validate(@)

      # if it is not a Deferred will be done immediately
      $.when.apply($, results).done () =>
        unless silent
          valid = true
          for attr, errors of @errors
            @emit "invalid:#{attr}", errors
            valid = false
          @emit if valid then "valid" else "invalid"
        dfd.resolve()

      dfd.promise()

    # Should only be used when there is no
    # asynchronous validation
    isValid: ( opts ) ->
      @validate opts
      for error of @errors
        return false
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

    addError: ( name, message ) ->
      @errors ?= {}
      @errors[ name ] ?= []
      @errors[ name ].push message

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
