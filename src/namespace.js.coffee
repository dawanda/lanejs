###

# Global Function: namespace( ns_string, [function] )

Creates a deeply namespaced object specified by `ns_string`, creating the
namespace if it does not exist but without overriding it if it exists.  If the
second argument `function` is provided, the object is set to the return value
of `function`, otherwise it is set to an empty object.
You can use this function to create an object nested into a namespace without
worrying if the namespace existed before or not.

## Usage:

```
namespace "Foo.Bar.Baz"
```

creates and returns the window.Foo.Bar.Baz object, setting it to an empty
object. The namespace is created if necessary, or "reopened" if it existed
before.

```
namespace "Foo.Bar.Baz", ->
  class Baz
    # definition of class Baz
```

creates and returns the window.Foo.Bar.Baz object, setting it to a class.

###

# Use UMD for better future compatibility https://github.com/umdjs/umd

((root, factory) ->
  if typeof define is "function" and define.amd?
    define [], ->
      root.namespace = factory(root)
  else if typeof exports is "object"
    module.exports = factory(root)
  else
    root.namespace = factory(root)
)(this, (root) ->
  ( ns, fn ) ->
    segments = ns.split "."
    last_segment_index = segments.length - 1
    parent = root
    if fn? and typeof fn isnt "function"
      throw new TypeError("second argument of 'namespace' should be a function")
    for segment, index in segments
      if index is last_segment_index and fn?
        parent[ segment ] = fn()
      else
        parent[ segment ] ?= {}
      parent = parent[ segment ]
    parent
)
