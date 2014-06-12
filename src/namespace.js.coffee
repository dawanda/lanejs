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

window.namespace = ( ns, fn ) ->
  segments = ns.split "."
  last_segment = segments[ segments.length - 1 ]
  parent = window
  if fn? and typeof fn is not "function"
    throw new TypeError("second argument of 'namespace' should be a function")
  for segment in segments
    if segment is last_segment and fn?
      parent[ segment ] = fn()
    else
      parent[ segment ] ?= {}
    parent = parent[ segment ]
  parent
