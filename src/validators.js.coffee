#= require dawanda/mixins/rate_limiter

# BaseValidator
#
# Validator with general options
# 'if' option runs in the context of the validated object

class BaseValidator extends Lib.Module

  constructor: ( attr, opts ) ->
    @options = {}
    @options[ key ] = val for key, val of opts

  validate: ( obj ) ->
    return @run( obj ) unless @options.if?
    if typeof @options.if is "string"
      condition = obj[ @options.if ]
    else
      condition = @options.if
    @run( obj ) if condition.call( obj ) is true

  run: ->
    throw "'run' method has to be implemented by BaseValidator subclasses"

# PresenceValidator
#
# Validates presence of an attribute. The error message can be configured using
# the 'message' option.
#
class PresenceValidator extends BaseValidator

  constructor: ( attr, opts ) ->
    opts = {} if opts is true
    super attr, opts
    @attribute = attr
    @options.message ?= I18n.t("errors.messages.empty")

  run: ( obj ) ->
    value = obj.get( @attribute )
    unless value? and ( value + "" ).length > 0
      obj.addError @attribute, @options.message

# FormatValidator
#
# Validates format of an attribute, specified as a regular expression in the
# 'with' option. The error message can be configured using the 'message'
# option.
#
class FormatValidator extends BaseValidator

  constructor: ( attr, opts ) ->
    super attr, opts
    @attribute = attr
    @options.message ?= I18n.t("errors.messages.invalid")

  run: ( obj ) ->
    value = obj.get @attribute
    return unless value? and ( value + "" ).length > 0 and @options.with?
    obj.addError @attribute, @options.message unless @options.with.test value

# RangeValidator
#
# Validates the range of a number. Using 'min' and 'max' option. The error 
# message can be configured using the 'message' option.
#
class RangeValidator extends BaseValidator

  constructor: ( attr, opts ) ->
    super attr, opts
    @attribute = attr
    @options.message ?= I18n.t("errors.messages.not_in_range")

  run: ( obj ) ->
    value = obj.get @attribute
    return unless value? and ( value + "" ).length > 0 and (@options.max? or @options.min?)
    if @options.min? and typeof @options.min is "function"
      @options.min = @options.min.call( obj )
    if @options.max? and typeof @options.max is "function"
      @options.max = @options.max.call( obj )

    if @options.min? and typeof @options.min is "object" and @options.min._isAMomentObject and !value.min(@options.min)
      obj.addError @attribute, @options.message
    else if @options.max? and typeof @options.max is "object" and @options.max._isAMomentObject and !value.max(@options.max)
      obj.addError @attribute, @options.message
    else if @options.min? and value < @options.min
      obj.addError @attribute, @options.message
    else if @options.max? and value > @options.max
      obj.addError @attribute, @options.message

# AcceptanceValidator
#
# Validates acceptance of an attribute. The acceptance value is '1' by default,
# and can be configured with the 'accept' option. The error message can be
# configured using the 'message' option.
#
class AcceptanceValidator extends BaseValidator

  constructor: ( attr, opts ) ->
    super attr, opts
    @attribute = attr
    @options.message ?= I18n.t("errors.messages.accepted")
    @options.accept  ?= "1"

  run: ( obj ) ->
    obj.addError @attribute, @options.message unless obj.get( @attribute ) is @options.accept

# LengthValidator
#
# Validates format of an attribute, specified as a regular expression in the
# 'with' option. The error message can be configured using the 'message'
# option.
#
class LengthValidator extends BaseValidator

  constructor: ( attr, opts ) ->
    super attr, opts
    @attribute = attr
    @options.too_long ?= I18n.t("errors.messages.too_long.other")
    @options.too_short ?= I18n.t("errors.messages.too_short.other")
    @options.wrong_length ?= I18n.t("errors.messages.wrong_length.other")

  run: ( obj ) ->
    value = "#{obj.get @attribute}"
    return unless value?
    obj.addError @attribute, @options.too_long if @options.max? and value.length > @options.max
    obj.addError @attribute, @options.too_short if @options.min? and value.length < @options.min
    obj.addError @attribute, @options.wrong_length if @options.is? and value.length != @options.is

# ConfirmationValidator
#
# Validates confirmation of an attribute, checking that its value is equal to
# another attribute named the same, plus a '_confirmation' suffix.
#
class ConfirmationValidator extends BaseValidator

  constructor: ( attr, opts ) ->
    super attr, opts
    @attribute = attr
    @confirmed_attribute = @options.confirmed_attribute || @attribute + "_confirmation"
    @options.message ?= I18n.t("errors.messages.confirmed")

  run: ( obj ) ->
    value           = obj.get( @attribute )
    confirmed_value = obj.get( @confirmed_attribute )
    return unless value? and ( value + "" ).length > 0
    unless value is confirmed_value
      obj.addError @confirmed_attribute, @options.message


namespace "Lib.Validators", ->
  # Export validators
  BaseValidator:         BaseValidator
  PresenceValidator:     PresenceValidator
  FormatValidator:       FormatValidator
  AcceptanceValidator:   AcceptanceValidator
  RangeValidator:        RangeValidator
  LengthValidator:       LengthValidator
  ConfirmationValidator: ConfirmationValidator
