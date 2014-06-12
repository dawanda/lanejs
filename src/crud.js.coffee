#= require url_builder

namespace "Lib.Crud", ->

  # Extending the model class with this class allows us to fetch and persist
  # data. The default strategy is to use a JSON API via AJAX, but this can be
  # configured by providing different Repo implementations (e.g. one based on
  # localStorage)
  #
  # Example:
  #
  #   class Product extends Lib.Model
  #     @extend Lib.Crud
  #     @endpoint "/sellers/:seller_id/products"
  #     @resource "product"
  #
  #   # Fetch the product with id 123
  #   # (will issue a GET /sellers/321/products/123)
  #   Product.find( seller_id: 321, id: 123 )
  #     .done ( product ) ->
  #       # product is a Product instance
  #
  #   # Fetch all the products in page 1
  #   # (will issue a GET /sellers/321/products?page=1)
  #   Product.findAll( seller_id: 321, page: 1 )
  #     .done ( products ) ->
  #       # products is an array of Product instances
  #
  #   # Create a product
  #   # (will issue a POST /sellers/321/products with body "title=foo&seller_id=321")
  #   product = new Product( title: "foo", seller_id: 321 )
  #   Product.create( product )
  #     .done ( product ) ->
  #       # Creation succeeded :)
  #       # product is a Product instance
  #     .fail ( error ) ->
  #       # Something failed. Check the error
  #
  #   # Update a product (assume product id is 123)
  #   # (will issue a PATCH /sellers/321/products/123 with body "id=123&title=bar&seller_id=321")
  #   product.set( "title", "bar" )
  #   Product.update( product )
  #     .done ->
  #       # Update succeeded :)
  #     .fail ( error ) ->
  #       # Something failed. Check the error
  #
  #   # Delete a product
  #   # (will issue a DELETE /products/123 with body "id=123&title=bar&seller_id=321")
  #   Product.delete( product )
  #     .done ->
  #       # Deletion succeeded :)
  #     .fail ( error ) ->
  #       # Something failed. Check the error
  #
  class Crud
    @resource: ( name ) ->
      @::resource = name if name?

    @endpoint: ( path, resource_name = @::resource ) ->
      throw "resource name should be specified" unless resource_name
      @repo = new @Repo( path, resource_name )

    @find: ( params ) ->
      if typeof params is "number" or typeof params is "string"
        params = { id: params }
      deferred = $.Deferred()
      @repo.read( @_objectify( params ) ).pipe ( data ) =>
        new @( data )

    @findAll: ( params ) ->
      @repo.readAll(  @_objectify( params ) ).pipe ( data_list ) =>
        ( new @( data ) for data in data_list )

    @update: ( model, validate = true ) ->
      if validate is false or typeof model.isValid is "undefined" or model.isValid()
        @repo.update( @_objectify( model ) )
      else
        deferred = $.Deferred()
        deferred.reject("validationError")
        deferred

    @create: ( model, validate = true ) ->
      if validate is false or typeof model.isValid is "undefined" or model.isValid()
        @repo.create( @_objectify( model ) ).pipe( ( data ) => new @( data ) )
      else
        deferred = $.Deferred()
        deferred.reject("validationError")
        deferred

    @delete: ( model ) ->
      deferred = $.Deferred()
      @repo.delete( @_objectify( model ) )

    @_objectify: ( thing ) ->
      if typeof thing?.serializeForCRUD is "function"
        thing.serializeForCRUD()
      else if typeof thing?.toJSON is "function"
        thing.toJSON()
      else
        thing

    class @Repo
      constructor: ( @_endpoint, @_resource_name ) ->

      create: ( data ) ->
        @_ajax "POST", Lib.URLBuilder.buildURL( @_endpoint, data, querystring: false ), @_wrap( data )

      read: ( data ) ->
        @_ajax "GET", Lib.URLBuilder.buildURL( "#{@_endpoint}/:id", data )

      readAll: ( data ) ->
        @_ajax "GET", Lib.URLBuilder.buildURL( @_endpoint, data )

      update: ( data ) ->
        @_ajax "PATCH", Lib.URLBuilder.buildURL( "#{@_endpoint}/:id", data, querystring: false ), @_wrap( data )

      delete: ( data ) ->
        @_ajax "DELETE", Lib.URLBuilder.buildURL( "#{@_endpoint}/:id", data, querystring: false ), @_wrap( data ), dataType: "text"

      _wrap: ( data ) ->
        obj = {}
        obj[ @_resource_name ] = data
        obj

      # perform AJAX call and normalize the returned promise
      _ajax: ( type, url, data = {}, opts = {} ) ->
        doneFilter    = ( returnData ) -> returnData
        failFilter    = ( _, status )  -> status
        opts.dataType ?= "json"
        $.ajax( type: type, dataType: opts.dataType, url: url, data: data ).pipe( doneFilter, failFilter )
