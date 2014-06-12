# This is a derivative work adapted from:
#   jQuery Cookie Plugin v1.3.1
#   https://github.com/carhartl/jquery-Cookie
#   Copyright 2013 Klaus Hartl
#   Released under the MIT license
#
namespace "Lib.Cookie", ->

  # A Cookie object represents a browser cookie. It's instantiated with the
  # name of the cookie and serialization options. Once a Cookie has been
  # initialized, the `get`, `set` and `delete` methods manipulate the value.
  #
  # It's very important to always access a particular cookie with the same
  # serialization options, or you may get some very odd behaviour.
  #
  # Example:
  #
  #   userPreferenceCookie = new Lib.Cookie('user_preferences', json: true)
  #   userPreferenceCookie.set(color: 'blue', page: 2)
  #
  #   # ...
  #
  #   userPreferences = userPreferenceCookie.get() || {color: 'black'}
  #   $('.panel').css('background', userPreferences.color)
  #
  class Cookie

    constructor: ( @key, @_config = {} ) ->
      unless @key?
        throw new Error("cookie key was not provided")

      @_config.defaults ?=
        Path: '/'

    set: ( value, opts = {} ) ->
      unless value?
        throw new Error "cookie value should be provided"

      for own k, v of @_config.defaults
        opts[ k ] = v unless opts[ k ]?

      if typeof opts.expires is "number"
        days = opts.expires
        date = new Date()
        date.setDate( date.getDate() + days )
        opts.expires = date.toUTCString()

      value = if @_config.json then JSON.stringify( value ) else "#{value}"

      unless @_config.raw
        value = @_encode value
        key   = @_encode key

      serialized_options = for k, v of opts
        "#{k}=#{v || ''}"

      document.cookie = "#{@key}=#{value};#{serialized_options.join(';')}"

    get: ->
      cookies = document.cookie.split('; ')
      for cookie, i in cookies
        parts = cookie.split('=')
        name  = parts.shift()
        value = parts.join('=')

        unless @_config.raw
          continue if @_encode(@key) isnt name
          try
            name  = @_decode name
            value = @_decode value
          catch _
            @reportError "Couldn't decode cookie #{name}"
            continue

        return @_convert( value ) if @key is name
      null

    # TODO shared message reporting
    reportError: (message) ->
      console.error message

    delete: ( opts = {} ) ->
      return false if not @get?

      # Must not alter original opts
      opts_clone = {}
      for k, v of opts
        opts_clone[ k ] = v
      opts_clone.expires = -1
      @set '', opts_clone
      true

    _decode: ( str ) ->
      decodeURIComponent str.replace( /\+/g, " " )

    _encode: ( str ) ->
      encodeURIComponent( str )

    _convert: ( str ) ->
      if /^"/.test str
        # This is a quoted cookie as according to RFC2068, unescape
        str = str[1...-1].replace(/\\"/g, '"').replace(/\\\\/g, '\\')

      if @_config.json
        JSON.parse str
      else
        str
