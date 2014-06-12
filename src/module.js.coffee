namespace "Lib.Module", ->

  module_keywords = ['extended', 'included']

  class Module

    @extend: (obj) ->
      for key, value of obj when key not in module_keywords
        @[key] = value

      obj.extended? @
      return @

    @include: (obj) ->
      for key, value of obj when key not in module_keywords
        @::[key] = value

      obj.included? @
      return @

    @extendAndInclude: ( klass ) ->
      unless klass::?
        throw new Error "extendAndInclude expects a constructor"
      @extend klass
      @include klass::
