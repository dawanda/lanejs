# Timeout
#
# A promise-based timeout utility.
#
# Usage:
#
# ```coffeescript
# # Simplest example, just like setTimeout but with the function as the last
# # argument:
# Lib.Timeout.start 1000, ->
#   console.log("Boom!")
#
# # Example with promises:
# timeout = Lib.Timeout.start(1000)
# timeout.then ->
#   console.log("Boom!")
# ```
#

#= require jquery

namespace "Lib.Timeout", ->

  class Timeout

    constructor: ( @milliseconds ) ->
      @deferred = new $.Deferred()

    start: ( fn ) ->
      callback = =>
        @deferred.resolve( @milliseconds )
      setTimeout( callback, @milliseconds )
      @deferred.then( fn ) if typeof fn is "function"
      @deferred

    @start: ( millis, fn ) ->
      t = new Timeout( millis ).start( fn )
