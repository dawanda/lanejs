#= require url_builder

namespace "Lib.Request", ->

  # The Request wraps a simple environment hash given to it, and adds some
  # simple convenience methods.
  #
  class Request

    constructor: (raw_request) ->
      for own key, value of raw_request
        @[key] = value

    newUrl: (new_params = {}) ->
      Lib.URLBuilder.buildURL( @pathname, new_params )
