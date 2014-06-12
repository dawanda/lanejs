# require lodash
namespace "Lib.Persistable", ->

  # Extending the model class this class allows us to persist a set 
  # of data by giving the possibility to rollback our data.
  #
  # Example:
  #
  #   class Product extends Lib.Model
  #     @include Lib.Persistable::
  #     @attrAccessible 'title', 'description', 'price'
  #
  #   product = new Product(title: 'Dress', price: 21.99)
  #   product.set "title", "Skirt"
  #   product.get "title" # Skirt
  #   product.rollback()
  #   product.get "title" # Dress
  #   
  #   product.set "title", "Necklace"
  #   product.changes() # {title: 'Necklace'}
  #   product.persist()
  #   product.rollback()
  #   product.get "title" # Necklace
  #
  class Persistable

    # Instance Methods
    rollback: ( opts = {} ) ->
      attrs = @_resetDirtyAttributes()
      unless opts? and opts.silent
        for name, value of attrs
          @emit "change:#{name}", name, @_attributes[ name ]
        @emit "rolled back", attrs

    persist: ( opts = {} ) ->
      attrs = @_resetDirtyAttributes()
      for name, value of attrs
        @_attributes[ name ] = value
      unless opts? and opts.silent
        @emit "persisted", attrs

    # Getting changed attributes as json
    changes: ->
      @_dirty_attributes ?= { }
      to_json = {}
      for key, value of @_dirty_attributes
        value = value.toJSON() if value?.toJSON?
        to_json[ key ] = value
      to_json

    set: ( name, value, opts ) ->
      @_dirty_attributes ?= {}
      @_attributes ?= {}

      unless opts? and opts.clean
        if _.isEqual(@_attributes[ name ], value)
          delete @_dirty_attributes[ name ]
        else
          @_dirty_attributes[ name ] = value
      else
        @_attributes[ name ] = value

      unless opts? and opts.silent
        @emit "change:#{name}", name, value

    get: ( name, opts ) ->
      @_dirty_attributes ?= {}
      @_attributes ?= {}

      value = @_dirty_attributes[ name ]
      value ?= @_attributes[ name ]

      unless opts? and opts.silent
        @emit "read:#{name}", name, value

      return value

    _resetDirtyAttributes: ->
      @_dirty_attributes ?= { }
      @_attributes ?= {}

      attrs = { }
      attrs[ name ] = value for name, value of @_dirty_attributes

      @_dirty_attributes = { }
      attrs