#= require dawanda/mixins/rate_limiter

# BaseValidator
#
# Validator with general options
# 'if' option runs in the context of the validated object

class BaseValidator extends Lib.Module

  # Instantiates validator object
  # @param attr - name of the attribute that is a subject to
  #   validation
  # @param opts - options for validator
  #   - option if - a condition when validator applies,
  #     can be either function or string,
  #     in case of string instance method on target object with the
  #     same name will be used
  constructor: ( attr, opts ) ->
    @options = {}
    # copy only key-value pairs for passed in opts object
    # since it can be an arbitrary object
    @options[ key ] = val for key, val of opts

  # Runs validation on passed in object
  # Delegates to run if there is no if condition or it is true
  # @param obj - subject to validation, model instance object
  validate: ( obj ) ->
    # delegate to run if there is no if option
    return @run( obj ) unless @options.if?
    # when if option is a string
    if typeof @options.if is "string"
      # fetch instance method with the same name on object
      condition = obj[ @options.if ]
    else
      # otherwise just use its value
      condition = @options.if
    # and delegate to run if its value when called in context of
    # object is true
    @run( obj ) if condition.call( obj ) is true

  # @abstract
  # Performs validation
  # @param obj - subject to validation
  run: ->
    throw "'run' method has to be implemented by BaseValidator subclasses"

# PresenceValidator
#
# Validates presence of an attribute. The error message can be configured using
# the 'message' option.
#
class PresenceValidator extends BaseValidator

  # Instantiates presence validator object
  # @param attr - the same as for BaseValidator
  # @param opts - the same as for BaseValidator, additionally:
  #   - message - error message, defaults to I18n.t("errors.messages.empty")
  constructor: ( attr, opts ) ->
    # clear options if it is just true
    opts = {} if opts is true
    # delegate to constructor of a superclass
    super attr, opts
    # store attribute that is a subject to validation
    # NOTE: Looks like this belongs to BaseValidator ?
    @attribute = attr
    # set message to a default value if it is not defined
    @options.message ?= I18n.t("errors.messages.empty")

  # Performs presence validation
  # @param obj - subject to validation
  run: ( obj ) ->
    # gets value of attribute on object
    value = obj.get( @attribute )
    # value should be truthy and its string representation shouldn't
    # be blank
    unless value? and ( value + "" ).length > 0
      # otherwise add error to object with attribute and configured
      # message
      obj.addError @attribute, @options.message

# FormatValidator
#
# Validates format of an attribute, specified as a regular expression in the
# 'with' option. The error message can be configured using the 'message'
# option.
#
class FormatValidator extends BaseValidator

  # Instantiates format validator object
  # @param attr - the same as for BaseValidator
  # @param opts - the same as for BaseValidator, additionally:
  #   - message - error message, defaults to I18n.t("errors.messages.invalid")
  #   - with - regex expression to test attribute value format against
  constructor: ( attr, opts ) ->
    super attr, opts
    @attribute = attr
    @options.message ?= I18n.t("errors.messages.invalid")

  # Performs presence validation
  # @param obj - subject to validation
  run: ( obj ) ->
    value = obj.get @attribute
    # ignore blank values and missing with option
    return unless value? and ( value + "" ).length > 0 and @options.with?
    # attribute value should match regex expression from with option
    obj.addError @attribute, @options.message unless @options.with.test value

# RangeValidator
#
# Validates the range of a number. Using 'min' and 'max' option. The error
# message can be configured using the 'message' option.
#
class RangeValidator extends BaseValidator

  # NOTE Omitting constructor comments from this point, unless there
  # is something interesting
  # @param opts - options:
  #   - message - defaults to I18n.t("errors.messages.not_in_range")
  #   - min - mimimal allowed attribute value
  #   - max - maximal allowed attribute value
  constructor: ( attr, opts ) ->
    super attr, opts
    @attribute = attr
    @options.minFunc = @options.min if @options.min? and typeof @options.min is "function"
    @options.maxFunc = @options.max if @options.max? and typeof @options.max is "function"
    @options.messageFunc = @options.message if @options.message? and typeof @options.message is "function"

  run: ( obj ) ->
    value = obj.get @attribute
    # ignore blank values and when both max and min options are missing
    return unless value? and ( value + "" ).length > 0 and (@options.max? or @options.min?)

    # Use the initially provided functions for min and max to update their values
    if @options.minFunc?
      @options.min = @options.minFunc.call( obj )
    if @options.maxFunc?
      @options.max = @options.maxFunc.call( obj )
    if @options.messageFunc?
      @options.message = @options.messageFunc.call( obj )
    else
      @options.message ?= I18n.t("errors.messages.not_in_range")

    # checks if actual value of attribute is between min and max,
    # accounting for possible absence of one of them
    #
    # handles datetimes from momentjs
    if @options.min? and typeof @options.min is "object" and @options.min._isAMomentObject and !value.min(@options.min)
      obj.addError @attribute, @options.message
    else if @options.max? and typeof @options.max is "object" and @options.max._isAMomentObject and !value.max(@options.max)
      obj.addError @attribute, @options.message
    # handles everything else
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

  # @param opts - options:
  #   - message - defaults to I18n.t("errors.messages.accepted")
  #   - accept - acceptance value, defaults to "1"
  constructor: ( attr, opts ) ->
    super attr, opts
    @attribute = attr
    @options.message ?= I18n.t("errors.messages.accepted")
    @options.accept  ?= "1"

  run: ( obj ) ->
    # attribute value should be equal to accept option value
    obj.addError @attribute, @options.message unless obj.get( @attribute ) is @options.accept

# LengthValidator
#
# Validates length of an attribute, specified as a range by 'min' and
# 'max' options, or specified by exact value by 'is' option. The error
# message can be configured using 'too_long' and 'too_short' options for
# range validation and 'wrong_length' option for 'is' validation.
#
class LengthValidator extends BaseValidator

  # @param opts - options:
  #   - wrong_length - error message used with 'is' option, defaults
  #     to I18n.t("errors.messages.wrong_length.other")
  #   - too_short - error message used with 'min' option, defaults
  #     to I18n.t("errors.messages.too_short.other")
  #   - too_long - error message used with 'max' option, defaults
  #     to I18n.t("errors.messages.too_long.other")
  #   - is - exact expected length
  #   - min - mimimal allowed length
  #   - max - maximal allowed length
  constructor: ( attr, opts ) ->
    super attr, opts
    @attribute = attr
    @options.too_long ?= I18n.t("errors.messages.too_long.other")
    @options.too_short ?= I18n.t("errors.messages.too_short.other")
    @options.wrong_length ?= I18n.t("errors.messages.wrong_length.other")

  run: ( obj ) ->
    # gets attribute value's string representation
    value = "#{obj.get @attribute}"
    # ignores blank values
    return unless value?
    # value should be <= max option if it is not missing
    obj.addError @attribute, @options.too_long if @options.max? and value.length > @options.max
    # value should be >= min option if it is not missing
    obj.addError @attribute, @options.too_short if @options.min? and value.length < @options.min
    # value should be == is option if it is not missing
    obj.addError @attribute, @options.wrong_length if @options.is? and value.length != @options.is

# ConfirmationValidator
#
# Validates confirmation of an attribute, checking that its value is equal to
# another attribute named the same, plus a '_confirmation' suffix. Confirmed
# attribute name can be customized with 'confirmed_attribute' option.
#
class ConfirmationValidator extends BaseValidator

  # @param opts - options:
  #   - message - defaults to I18n.t("errors.messages.confirmed")
  #   - confirmed_attribute - another attribute name, defaults to
  #     <attribute>_confirmation
  constructor: ( attr, opts ) ->
    super attr, opts
    @attribute = attr
    # NOTE Why not `@options.confirmed_attribute ?= @attribute + "_confirmation"` ?
    #      and than in `run` use @options.confirmed_attribute
    @confirmed_attribute = @options.confirmed_attribute || @attribute + "_confirmation"
    @options.message ?= I18n.t("errors.messages.confirmed")

  run: ( obj ) ->
    # get both attributes' value
    value           = obj.get( @attribute )
    confirmed_value = obj.get( @confirmed_attribute )
    # ignore blank value
    return unless value? and ( value + "" ).length > 0
    # both values should be the same
    unless value is confirmed_value
      obj.addError @confirmed_attribute, @options.message


# export builtin validators under Lib.Validators namespace
namespace "Lib.Validators", ->
  # Export validators
  BaseValidator:         BaseValidator
  PresenceValidator:     PresenceValidator
  FormatValidator:       FormatValidator
  AcceptanceValidator:   AcceptanceValidator
  RangeValidator:        RangeValidator
  LengthValidator:       LengthValidator
  ConfirmationValidator: ConfirmationValidator
