class I18n

  @translate: ( key, obj = {} ) ->
    translation = resolve( window.Translations, key )
    if translation?
      for key, value of obj
        regexp = new RegExp "%\\{\\s*#{ key }\\s*\\}"
        translation = translation.replace regexp, value
    else if obj.default?
      translation = obj.default
      for key, value of obj
        regexp = new RegExp "%\\{\\s*#{ key }\\s*\\}"
        translation = translation.replace regexp, value
    else
      key_segments = key.split(".")
      translation = key_segments[ key_segments.length - 1 ].replace("_", " ")
    translation

  @t: @translate

  resolve = ( obj, key ) ->
    return null unless obj?
    key_copy = key + ""
    value    = null
    path     = []
    while key_copy.length and not value = obj[ key_copy ]
      segments = key_copy.split(".")
      path.push segments.pop()
      key_copy = segments.join(".")
    while value? and path.length > 0
      value = value[ path.pop() ]
    return value


@I18n = I18n
@t = ( args... ) ->
  I18n.t args...