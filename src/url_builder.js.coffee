namespace "Lib.URLBuilder", ->
  # e.g.:
  # `buildURL("/foo/:id", { id: 123, bar: "baz", qux: [1, 2] })`
  # would return `"/foo/123?bar=baz&qux[]=1&qux[]=2"`
  buildURL: ( template, params, options = {} ) ->
    # defensive copy
    params = $.extend( {}, params )
    re = /:([\w\d]+)/g
    path = template.replace re, ( match, name ) ->
      value = encodeURIComponent params[ name ]
      delete params[ name ]
      value
    return path if options.querystring is false
    querystr = $.param( params )
    if querystr.length > 0
      if /\?/.test path
        querystr = "&#{querystr}"
      else
        querystr = "?#{querystr}"
    "#{path}#{querystr}"
