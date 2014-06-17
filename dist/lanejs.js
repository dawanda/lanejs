
/*

 * Global Function: namespace( ns_string, [function] )

Creates a deeply namespaced object specified by `ns_string`, creating the
namespace if it does not exist but without overriding it if it exists.  If the
second argument `function` is provided, the object is set to the return value
of `function`, otherwise it is set to an empty object.
You can use this function to create an object nested into a namespace without
worrying if the namespace existed before or not.

 *# Usage:

```
namespace "Foo.Bar.Baz"
```

creates and returns the window.Foo.Bar.Baz object, setting it to an empty
object. The namespace is created if necessary, or "reopened" if it existed
before.

```
namespace "Foo.Bar.Baz", ->
  class Baz
     * definition of class Baz
```

creates and returns the window.Foo.Bar.Baz object, setting it to a class.
 */

(function() {
  var AcceptanceValidator, BaseValidator, FormatValidator, I18n, LengthValidator, PresenceValidator, RangeValidator,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  window.namespace = function(ns, fn) {
    var last_segment, parent, segment, segments, _i, _len;
    segments = ns.split(".");
    last_segment = segments[segments.length - 1];
    parent = window;
    if ((fn != null) && typeof fn === !"function") {
      throw new TypeError("second argument of 'namespace' should be a function");
    }
    for (_i = 0, _len = segments.length; _i < _len; _i++) {
      segment = segments[_i];
      if (segment === last_segment && (fn != null)) {
        parent[segment] = fn();
      } else {
        if (parent[segment] == null) {
          parent[segment] = {};
        }
      }
      parent = parent[segment];
    }
    return parent;
  };

  namespace("Lib.Module", function() {
    var Module, module_keywords;
    module_keywords = ['extended', 'included'];
    return Module = (function() {
      function Module() {}

      Module.extend = function(obj) {
        var key, value;
        for (key in obj) {
          value = obj[key];
          if (__indexOf.call(module_keywords, key) < 0) {
            this[key] = value;
          }
        }
        if (typeof obj.extended === "function") {
          obj.extended(this);
        }
        return this;
      };

      Module.include = function(obj) {
        var key, value;
        for (key in obj) {
          value = obj[key];
          if (__indexOf.call(module_keywords, key) < 0) {
            this.prototype[key] = value;
          }
        }
        if (typeof obj.included === "function") {
          obj.included(this);
        }
        return this;
      };

      Module.extendAndInclude = function(klass) {
        if (klass.prototype == null) {
          throw new Error("extendAndInclude expects a constructor");
        }
        this.extend(klass);
        return this.include(klass.prototype);
      };

      return Module;

    })();
  });

  namespace("Lib.Timeout", function() {
    var Timeout;
    return Timeout = (function() {
      function Timeout(milliseconds) {
        this.milliseconds = milliseconds;
        this.deferred = new $.Deferred();
      }

      Timeout.prototype.start = function(fn) {
        var callback;
        callback = (function(_this) {
          return function() {
            return _this.deferred.resolve(_this.milliseconds);
          };
        })(this);
        setTimeout(callback, this.milliseconds);
        if (typeof fn === "function") {
          this.deferred.then(fn);
        }
        return this.deferred;
      };

      Timeout.start = function(millis, fn) {
        var t;
        return t = new Timeout(millis).start(fn);
      };

      return Timeout;

    })();
  });

  namespace("Lib.Model", function() {
    var Model;
    return Model = (function(_super) {
      __extends(Model, _super);

      Model.include(LoudAccessors.prototype);

      function Model(attrs) {
        var name, value;
        for (name in attrs) {
          value = attrs[name];
          this.set(name, value, {
            clean: true
          });
        }
        this.emit("initialized", attrs);
      }

      Model.addValidation = function(validation) {
        var _base;
        if ((_base = this.prototype)._validations == null) {
          _base._validations = [];
        }
        if (!this.prototype.hasOwnProperty("_validations")) {
          this.prototype._validations = this.prototype._validations.slice(0);
        }
        return this.prototype._validations.push(validation);
      };

      Model.validatesPresenceOf = function(attr, opts) {
        return this.validatesWith(Lib.Validators.PresenceValidator, attr, opts);
      };

      Model.validatesFormatOf = function(attr, opts) {
        return this.validatesWith(Lib.Validators.FormatValidator, attr, opts);
      };

      Model.validatesRangeOf = function(attr, opts) {
        return this.validatesWith(Lib.Validators.RangeValidator, attr, opts);
      };

      Model.validatesAcceptanceOf = function(attr, opts) {
        return this.validatesWith(Lib.Validators.AcceptanceValidator, attr, opts);
      };

      Model.validatesServerSideOf = function(attr, opts) {
        return this.validatesWith(Lib.Validators.ServerSideValidator, attr, opts);
      };

      Model.validates = function(attr, validations) {
        var capitalized, opts, type, _results;
        _results = [];
        for (type in validations) {
          opts = validations[type];
          capitalized = type.charAt(0).toUpperCase() + type.slice(1);
          _results.push(this["validates" + capitalized + "Of"](attr, opts));
        }
        return _results;
      };

      Model.validatesWith = function() {
        var Validator, args;
        Validator = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        return this.addValidation((function(func, args, ctor) {
          ctor.prototype = func.prototype;
          var child = new ctor, result = func.apply(child, args);
          return Object(result) === result ? result : child;
        })(Validator, args, function(){}));
      };

      Model.attrAccessible = function() {
        var attr, attrs, _base, _i, _len, _results;
        attrs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if ((_base = this.prototype)._attr_accessible == null) {
          _base._attr_accessible = [];
        }
        if (!this.prototype.hasOwnProperty("_attr_accessible")) {
          this.prototype._attr_accessible = this.prototype._attr_accessible.slice(0);
        }
        _results = [];
        for (_i = 0, _len = attrs.length; _i < _len; _i++) {
          attr = attrs[_i];
          if (__indexOf.call(this.prototype._attr_accessible, attr) < 0) {
            _results.push(this.prototype._attr_accessible.push(attr));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      };

      Model.prototype.validate = function(opts) {
        var dfd, results, silent, validation, _i, _len, _ref;
        this.errors = {};
        results = [];
        silent = (opts != null) && opts.silent;
        dfd = new $.Deferred;
        if (!silent) {
          this.emit("validate");
        }
        _ref = this._validations || [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          validation = _ref[_i];
          results.push(validation.validate(this));
        }
        $.when.apply($, results).done((function(_this) {
          return function() {
            var attr, errors, valid, _ref1;
            if (!silent) {
              valid = true;
              _ref1 = _this.errors;
              for (attr in _ref1) {
                errors = _ref1[attr];
                _this.emit("invalid:" + attr, errors);
                valid = false;
              }
              _this.emit(valid ? "valid" : "invalid");
            }
            return dfd.resolve();
          };
        })(this));
        return dfd.promise();
      };

      Model.prototype.isValid = function(opts) {
        var error;
        this.validate(opts);
        for (error in this.errors) {
          return false;
        }
        return true;
      };

      Model.prototype.isBlank = function() {
        var attribute_names, attributes, k, v, _ref;
        attribute_names = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (attribute_names.length > 0) {
          attributes = {};
          _ref = this._attributes;
          for (k in _ref) {
            v = _ref[k];
            if (__indexOf.call(attribute_names, k) >= 0) {
              attributes[k] = v;
            }
          }
        } else {
          attributes = this._attributes;
        }
        for (k in attributes) {
          v = attributes[k];
          if ((v != null) && v !== '') {
            return false;
          }
        }
        return true;
      };

      Model.prototype.addError = function(name, message) {
        var _base;
        if (this.errors == null) {
          this.errors = {};
        }
        if ((_base = this.errors)[name] == null) {
          _base[name] = [];
        }
        return this.errors[name].push(message);
      };

      Model.prototype.addErrorToBase = function(message) {
        return this.addError("_base_", message);
      };

      Model.prototype.toJSON = function() {
        var key, to_json, value, _ref;
        to_json = {};
        _ref = this._attributes;
        for (key in _ref) {
          value = _ref[key];
          if ((value != null ? value.toJSON : void 0) != null) {
            value = value.toJSON();
          }
          to_json[key] = value;
        }
        return to_json;
      };

      Model.prototype.reset = function(attribute) {
        this.untouch(attribute);
        return this.set(attribute, null);
      };

      Model.prototype.touch = function(attribute) {
        if (this.touched == null) {
          this.touched = {};
        }
        this.touched[attribute] = true;
        return this.emit("touched:" + attribute, attribute);
      };

      Model.prototype.untouch = function(attribute) {
        if (this.touched == null) {
          this.touched = {};
        }
        this.touched[attribute] = false;
        return this.emit("untouched:" + attribute, attribute);
      };

      Model.prototype.isTouched = function(attribute) {
        if (this.touched == null) {
          this.touched = {};
        }
        return !!this.touched[attribute];
      };

      return Model;

    })(Lib.Module);
  });

  namespace("Lib.Persistable", function() {
    var Persistable;
    return Persistable = (function() {
      function Persistable() {}

      Persistable.prototype.rollback = function(opts) {
        var attrs, name, value;
        if (opts == null) {
          opts = {};
        }
        attrs = this._resetDirtyAttributes();
        if (!((opts != null) && opts.silent)) {
          for (name in attrs) {
            value = attrs[name];
            this.emit("change:" + name, name, this._attributes[name]);
          }
          return this.emit("rolled back", attrs);
        }
      };

      Persistable.prototype.persist = function(opts) {
        var attrs, name, value;
        if (opts == null) {
          opts = {};
        }
        attrs = this._resetDirtyAttributes();
        for (name in attrs) {
          value = attrs[name];
          this._attributes[name] = value;
        }
        if (!((opts != null) && opts.silent)) {
          return this.emit("persisted", attrs);
        }
      };

      Persistable.prototype.changes = function() {
        var key, to_json, value, _ref;
        if (this._dirty_attributes == null) {
          this._dirty_attributes = {};
        }
        to_json = {};
        _ref = this._dirty_attributes;
        for (key in _ref) {
          value = _ref[key];
          if ((value != null ? value.toJSON : void 0) != null) {
            value = value.toJSON();
          }
          to_json[key] = value;
        }
        return to_json;
      };

      Persistable.prototype.set = function(name, value, opts) {
        if (this._dirty_attributes == null) {
          this._dirty_attributes = {};
        }
        if (this._attributes == null) {
          this._attributes = {};
        }
        if (!((opts != null) && opts.clean)) {
          if (_.isEqual(this._attributes[name], value)) {
            delete this._dirty_attributes[name];
          } else {
            this._dirty_attributes[name] = value;
          }
        } else {
          this._attributes[name] = value;
        }
        if (!((opts != null) && opts.silent)) {
          return this.emit("change:" + name, name, value);
        }
      };

      Persistable.prototype.get = function(name, opts) {
        var value;
        if (this._dirty_attributes == null) {
          this._dirty_attributes = {};
        }
        if (this._attributes == null) {
          this._attributes = {};
        }
        value = this._dirty_attributes[name];
        if (value == null) {
          value = this._attributes[name];
        }
        if (!((opts != null) && opts.silent)) {
          this.emit("read:" + name, name, value);
        }
        return value;
      };

      Persistable.prototype._resetDirtyAttributes = function() {
        var attrs, name, value, _ref;
        if (this._dirty_attributes == null) {
          this._dirty_attributes = {};
        }
        if (this._attributes == null) {
          this._attributes = {};
        }
        attrs = {};
        _ref = this._dirty_attributes;
        for (name in _ref) {
          value = _ref[name];
          attrs[name] = value;
        }
        this._dirty_attributes = {};
        return attrs;
      };

      return Persistable;

    })();
  });

  namespace("Lib.Crud", function() {
    var Crud;
    return Crud = (function() {
      function Crud() {}

      Crud.resource = function(name) {
        if (name != null) {
          return this.prototype.resource = name;
        }
      };

      Crud.endpoint = function(path, resource_name) {
        if (resource_name == null) {
          resource_name = this.prototype.resource;
        }
        if (!resource_name) {
          throw "resource name should be specified";
        }
        return this.repo = new this.Repo(path, resource_name);
      };

      Crud.find = function(params) {
        var deferred;
        if (typeof params === "number" || typeof params === "string") {
          params = {
            id: params
          };
        }
        deferred = $.Deferred();
        return this.repo.read(this._objectify(params)).pipe((function(_this) {
          return function(data) {
            return new _this(data);
          };
        })(this));
      };

      Crud.findAll = function(params) {
        return this.repo.readAll(this._objectify(params)).pipe((function(_this) {
          return function(data_list) {
            var data, _i, _len, _results;
            _results = [];
            for (_i = 0, _len = data_list.length; _i < _len; _i++) {
              data = data_list[_i];
              _results.push(new _this(data));
            }
            return _results;
          };
        })(this));
      };

      Crud.update = function(model, validate) {
        var deferred;
        if (validate == null) {
          validate = true;
        }
        if (validate === false || typeof model.isValid === "undefined" || model.isValid()) {
          return this.repo.update(this._objectify(model));
        } else {
          deferred = $.Deferred();
          deferred.reject("validationError");
          return deferred;
        }
      };

      Crud.create = function(model, validate) {
        var deferred;
        if (validate == null) {
          validate = true;
        }
        if (validate === false || typeof model.isValid === "undefined" || model.isValid()) {
          return this.repo.create(this._objectify(model)).pipe((function(_this) {
            return function(data) {
              return new _this(data);
            };
          })(this));
        } else {
          deferred = $.Deferred();
          deferred.reject("validationError");
          return deferred;
        }
      };

      Crud["delete"] = function(model) {
        var deferred;
        deferred = $.Deferred();
        return this.repo["delete"](this._objectify(model));
      };

      Crud._objectify = function(thing) {
        if (typeof (thing != null ? thing.serializeForCRUD : void 0) === "function") {
          return thing.serializeForCRUD();
        } else if (typeof (thing != null ? thing.toJSON : void 0) === "function") {
          return thing.toJSON();
        } else {
          return thing;
        }
      };

      Crud.Repo = (function() {
        function Repo(_endpoint, _resource_name) {
          this._endpoint = _endpoint;
          this._resource_name = _resource_name;
        }

        Repo.prototype.create = function(data) {
          return this._ajax("POST", Lib.URLBuilder.buildURL(this._endpoint, data, {
            querystring: false
          }), this._wrap(data));
        };

        Repo.prototype.read = function(data) {
          return this._ajax("GET", Lib.URLBuilder.buildURL("" + this._endpoint + "/:id", data));
        };

        Repo.prototype.readAll = function(data) {
          return this._ajax("GET", Lib.URLBuilder.buildURL(this._endpoint, data));
        };

        Repo.prototype.update = function(data) {
          return this._ajax("PATCH", Lib.URLBuilder.buildURL("" + this._endpoint + "/:id", data, {
            querystring: false
          }), this._wrap(data));
        };

        Repo.prototype["delete"] = function(data) {
          return this._ajax("DELETE", Lib.URLBuilder.buildURL("" + this._endpoint + "/:id", data, {
            querystring: false
          }), this._wrap(data), {
            dataType: "text"
          });
        };

        Repo.prototype._wrap = function(data) {
          var obj;
          obj = {};
          obj[this._resource_name] = data;
          return obj;
        };

        Repo.prototype._ajax = function(type, url, data, opts) {
          var doneFilter, failFilter;
          if (data == null) {
            data = {};
          }
          if (opts == null) {
            opts = {};
          }
          doneFilter = function(returnData) {
            return returnData;
          };
          failFilter = function(_, status) {
            return status;
          };
          if (opts.dataType == null) {
            opts.dataType = "json";
          }
          return $.ajax({
            type: type,
            dataType: opts.dataType,
            url: url,
            data: data
          }).pipe(doneFilter, failFilter);
        };

        return Repo;

      })();

      return Crud;

    })();
  });

  namespace("Lib.Controller", function() {
    var Controller;
    return Controller = (function(_super) {
      var isArray, peek, turnIntoArray;

      __extends(Controller, _super);

      peek = function(array, idx) {
        if (idx == null) {
          idx = 1;
        }
        return array[array.length - idx];
      };

      isArray = Array.isArray || function(maybe_array) {
        return {}.toString.call(maybe_array) === "[object Array]";
      };

      turnIntoArray = function(obj) {
        if (obj == null) {
          return [];
        }
        if (!isArray(obj)) {
          obj = [obj];
        }
        return obj;
      };

      function Controller(request) {
        this._buildEnv(request);
      }

      Controller.appendFilter = function() {
        var chain, filter, filters, item, key, opts, prop_name, type, val, _base, _i, _len, _results;
        type = arguments[0], filters = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        opts = {};
        if (typeof peek(filters) === "object") {
          opts = filters.pop();
        }
        opts.only = turnIntoArray(opts.only);
        opts.except = turnIntoArray(opts.except);
        prop_name = "_" + type + "_filters";
        if ((_base = this.prototype)[prop_name] == null) {
          _base[prop_name] = [];
        }
        if (!this.prototype.hasOwnProperty(prop_name)) {
          this.prototype[prop_name] = this.prototype[prop_name].slice(0);
        }
        chain = this.prototype[prop_name];
        _results = [];
        for (_i = 0, _len = filters.length; _i < _len; _i++) {
          filter = filters[_i];
          item = {
            fn: filter
          };
          for (key in opts) {
            val = opts[key];
            item[key] = val;
          }
          _results.push(chain.push(item));
        }
        return _results;
      };

      Controller.beforeFilter = function() {
        var filters;
        filters = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return this.appendFilter.apply(this, ["before"].concat(__slice.call(filters)));
      };

      Controller.afterFilter = function() {
        var filters;
        filters = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return this.appendFilter.apply(this, ["after"].concat(__slice.call(filters)));
      };

      Controller.action = function(name) {
        var Self;
        Self = this;
        return function() {
          var args, instance;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          instance = (function(func, args, ctor) {
            ctor.prototype = func.prototype;
            var child = new ctor, result = func.apply(child, args);
            return Object(result) === result ? result : child;
          })(Self, args, function(){});
          instance._executeFiltersForAction(name, "before");
          instance[name]();
          return instance._executeFiltersForAction(name, "after");
        };
      };

      Controller.hasAction = function(name) {
        return typeof this.prototype[name] === "function";
      };

      Controller.prototype._buildEnv = function(request) {
        this.request = request || {};
        return this.params = this.request.params || {};
      };

      Controller.prototype._executeFiltersForAction = function(action, type) {
        var filter, filters, fn, _i, _len, _results;
        filters = this["_" + type + "_filters"] || [];
        _results = [];
        for (_i = 0, _len = filters.length; _i < _len; _i++) {
          filter = filters[_i];
          if (filter.only.length === 0 || __indexOf.call(filter.only, action) >= 0) {
            if (__indexOf.call(filter.except, action) < 0) {
              fn = filter.fn;
              if (typeof fn === "string") {
                fn = this[fn];
              }
              _results.push(fn.call(this));
            } else {
              _results.push(void 0);
            }
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      };

      return Controller;

    })(Lib.Module);
  });

  namespace("Lib.Request", function() {
    var Request;
    return Request = (function() {
      function Request(raw_request) {
        var key, value;
        for (key in raw_request) {
          if (!__hasProp.call(raw_request, key)) continue;
          value = raw_request[key];
          this[key] = value;
        }
      }

      Request.prototype.newUrl = function(new_params) {
        if (new_params == null) {
          new_params = {};
        }
        return Lib.URLBuilder.buildURL(this.pathname, new_params);
      };

      return Request;

    })();
  });

  namespace("Lib.Cookie", function() {
    var Cookie;
    return Cookie = (function() {
      function Cookie(key, _config) {
        var _base;
        this.key = key;
        this._config = _config != null ? _config : {};
        if (this.key == null) {
          throw new Error("cookie key was not provided");
        }
        if ((_base = this._config).defaults == null) {
          _base.defaults = {
            Path: '/'
          };
        }
      }

      Cookie.prototype.set = function(value, opts) {
        var date, days, k, key, serialized_options, v, _ref;
        if (opts == null) {
          opts = {};
        }
        if (value == null) {
          throw new Error("cookie value should be provided");
        }
        _ref = this._config.defaults;
        for (k in _ref) {
          if (!__hasProp.call(_ref, k)) continue;
          v = _ref[k];
          if (opts[k] == null) {
            opts[k] = v;
          }
        }
        if (typeof opts.expires === "number") {
          days = opts.expires;
          date = new Date();
          date.setDate(date.getDate() + days);
          opts.expires = date.toUTCString();
        }
        value = this._config.json ? JSON.stringify(value) : "" + value;
        if (!this._config.raw) {
          value = this._encode(value);
          key = this._encode(key);
        }
        serialized_options = (function() {
          var _results;
          _results = [];
          for (k in opts) {
            v = opts[k];
            _results.push("" + k + "=" + (v || ''));
          }
          return _results;
        })();
        return document.cookie = "" + this.key + "=" + value + ";" + (serialized_options.join(';'));
      };

      Cookie.prototype.get = function() {
        var cookie, cookies, i, name, parts, value, _, _i, _len;
        cookies = document.cookie.split('; ');
        for (i = _i = 0, _len = cookies.length; _i < _len; i = ++_i) {
          cookie = cookies[i];
          parts = cookie.split('=');
          name = parts.shift();
          value = parts.join('=');
          if (!this._config.raw) {
            if (this._encode(this.key) !== name) {
              continue;
            }
            try {
              name = this._decode(name);
              value = this._decode(value);
            } catch (_error) {
              _ = _error;
              this.reportError("Couldn't decode cookie " + name);
              continue;
            }
          }
          if (this.key === name) {
            return this._convert(value);
          }
        }
        return null;
      };

      Cookie.prototype.reportError = function(message) {
        return console.error(message);
      };

      Cookie.prototype["delete"] = function(opts) {
        var k, opts_clone, v;
        if (opts == null) {
          opts = {};
        }
        if (this.get == null) {
          return false;
        }
        opts_clone = {};
        for (k in opts) {
          v = opts[k];
          opts_clone[k] = v;
        }
        opts_clone.expires = -1;
        this.set('', opts_clone);
        return true;
      };

      Cookie.prototype._decode = function(str) {
        return decodeURIComponent(str.replace(/\+/g, " "));
      };

      Cookie.prototype._encode = function(str) {
        return encodeURIComponent(str);
      };

      Cookie.prototype._convert = function(str) {
        if (/^"/.test(str)) {
          str = str.slice(1, -1).replace(/\\"/g, '"').replace(/\\\\/g, '\\');
        }
        if (this._config.json) {
          return JSON.parse(str);
        } else {
          return str;
        }
      };

      return Cookie;

    })();
  });

  namespace("Lib.Navigator", function() {
    var Navigator;
    return Navigator = (function(_super) {
      var _popped;

      __extends(Navigator, _super);

      _popped = false;

      Navigator.include(EventSpitter.prototype);

      function Navigator() {
        if (__indexOf.call($.event.props, "state") < 0) {
          $.event.props.push("state");
        }
        this._last_fragment = this.getFragment();
        $(window).on("popstate.navigator", (function(_this) {
          return function(evt) {
            return _this._popStateHandler(evt);
          };
        })(this));
      }

      Navigator.prototype.navigate = function(fragment, params) {
        if (params == null) {
          params = {};
        }
        fragment = this.buildFragment(fragment, params);
        if (fragment !== this.getFragment()) {
          this._pushState(params, null, fragment);
          if (!this._refreshingPage) {
            this._last_fragment = fragment;
            return this.emit("navigate", fragment, params);
          }
        }
      };

      Navigator.prototype.buildFragment = function(fragment, params) {
        if (params == null) {
          params = {};
        }
        return Lib.URLBuilder.buildURL(fragment, params);
      };

      Navigator.prototype.getFragment = function() {
        return location.pathname + location.search;
      };

      Navigator.prototype._pushState = function(data, title, url) {
        if (data == null) {
          data = {};
        }
        if (title == null) {
          title = null;
        }
        this._popped = true;
        if (this._hasPushState()) {
          return history.pushState({
            _navigator: data
          }, title, url);
        } else {
          return this._pageRefresh(url);
        }
      };

      Navigator.prototype._popStateHandler = function(evt) {
        var fragment, state;
        state = evt.state;
        if ((state != null) && (state._navigator != null)) {
          fragment = this.getFragment();
          this._last_fragment = fragment;
          this.emit("navigate", fragment, state._navigator);
        } else if (this._last_fragment !== this.getFragment()) {
          if (this._popped) {
            this._pageRefresh(this.getFragment());
          }
        }
        return this._popped = true;
      };

      Navigator.prototype._pageRefresh = function(url) {
        this._refreshingPage = true;
        return window.location = url;
      };

      Navigator.prototype._hasPushState = function() {
        return (typeof history !== "undefined" && history !== null ? history.pushState : void 0) != null;
      };

      Navigator.prototype._isInitialPop = function() {
        return this._initial_pop;
      };

      Navigator.prototype._popped = _popped;

      return Navigator;

    })(Lib.Module);
  });

  namespace("Lib.Router", function() {
    var Router;
    return Router = (function(_super) {
      var camelize, isArray, peek;

      __extends(Router, _super);

      camelize = function(str) {
        return str.replace(/(?:^|[-_])(\w)/g, function(m, c) {
          return (c || "").toUpperCase();
        });
      };

      isArray = Array.isArray || function(maybe_array) {
        return {}.toString.call(maybe_array) === "[object Array]";
      };

      peek = function(array, idx) {
        if (idx == null) {
          idx = 1;
        }
        return array[array.length - idx];
      };

      function Router() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        this.resource_routes = {
          show: "",
          "new": "/new",
          edit: "/edit"
        };
        this.resources_routes = {
          index: "",
          "new": "/new",
          show: "/:id",
          edit: "/:id/edit"
        };
        if (this._resource_stack == null) {
          this._resource_stack = [];
        }
        if (Router.__super__.constructor.apply(this, arguments) != null) {
          Router.__super__.constructor.apply(this, args);
        }
      }

      Router.prototype.lookupController = function(controller_name) {
        var m, module, module_stack, _i, _len;
        module = this.controllers || window;
        module_stack = this._module_stack || [];
        for (_i = 0, _len = module_stack.length; _i < _len; _i++) {
          m = module_stack[_i];
          module = module[m];
        }
        if (module[controller_name] == null) {
          throw new Error("" + (module_stack.join('.')) + "." + controller_name + " is null or undefined");
        }
        return module[controller_name];
      };

      Router.prototype.resourceToController = function(resource) {
        var controller_name;
        controller_name = "" + (camelize(resource)) + "Controller";
        return this.lookupController(controller_name);
      };

      Router.prototype.match = function(path, action_str) {
        var action, controller, resource, split;
        split = action_str.split("#");
        resource = split[0];
        action = split[1];
        controller = this.resourceToController(resource);
        return this.map(path, controller.action(action));
      };

      Router.prototype.scope = Cartograph.prototype.namespace;

      Router.prototype.namespace = function(ns, fn) {
        if (this._module_stack == null) {
          this._module_stack = [];
        }
        this._module_stack.push(camelize(ns));
        try {
          return Router.__super__.namespace.call(this, ns, fn);
        } finally {
          this._module_stack.pop();
        }
      };

      Router.prototype.resources = function(name, opts, fn) {
        var controller, controller_name, outer_resource, prefix, _ref;
        if (opts == null) {
          opts = {};
        }
        if (typeof opts === "function" && (fn == null)) {
          _ref = [opts, {}], fn = _ref[0], opts = _ref[1];
        }
        controller_name = (opts != null ? opts.controller : void 0) || name;
        controller = this.resourceToController(controller_name);
        outer_resource = peek(this._resource_stack);
        prefix = "";
        if (outer_resource != null) {
          prefix = "/:" + outer_resource.name + "_id";
        }
        return this.scope("" + prefix + "/" + name, function() {
          var action, actions, key, routes, value, _i, _len, _results;
          this._resource_stack.push({
            name: name,
            opts: opts
          });
          try {
            if (fn != null) {
              fn.call(this);
            }
          } finally {
            this._resource_stack.pop();
          }
          routes = (opts != null ? opts.singular : void 0) ? this.resource_routes : this.resources_routes;
          actions = ((function() {
            var _results;
            _results = [];
            for (key in routes) {
              if (!__hasProp.call(routes, key)) continue;
              value = routes[key];
              _results.push([key, value]);
            }
            return _results;
          })()).sort(function(a, b) {
            return a[1].replace(":id", "").length < b[1].replace(":id", "").length;
          }).map(function(a) {
            return a[0];
          });
          _results = [];
          for (_i = 0, _len = actions.length; _i < _len; _i++) {
            action = actions[_i];
            if (controller.hasAction(action)) {
              _results.push(this.match(routes[action], "" + controller_name + "#" + action));
            } else {
              _results.push(void 0);
            }
          }
          return _results;
        });
      };

      Router.prototype.resource = function(name, opts, fn) {
        var _ref;
        if (typeof opts === "function" && (fn == null)) {
          _ref = [opts, {}], fn = _ref[0], opts = _ref[1];
        }
        if (opts == null) {
          opts = {};
        }
        opts.singular = true;
        return this.resources(name, opts, fn);
      };

      Router.prototype.addAction = function(action, route) {
        var controller, controller_name, resource, _ref;
        resource = peek(this._resource_stack);
        if (resource == null) {
          throw new Error("no resource defined");
        }
        controller_name = ((_ref = resource.opts) != null ? _ref.controller : void 0) || resource.name;
        controller = this.resourceToController(controller_name);
        if (controller.hasAction(action)) {
          return this.match(route, "" + controller_name + "#" + action);
        }
      };

      Router.prototype.member = function(action) {
        var a, _i, _len, _results;
        if (!isArray(action)) {
          return this.addAction(action, "/:id/" + action);
        }
        _results = [];
        for (_i = 0, _len = action.length; _i < _len; _i++) {
          a = action[_i];
          _results.push(this.member(a));
        }
        return _results;
      };

      Router.prototype.collection = function(action) {
        var a, _i, _len, _results;
        if (!isArray(action)) {
          return this.addAction(action, "/" + action);
        }
        _results = [];
        for (_i = 0, _len = action.length; _i < _len; _i++) {
          a = action[_i];
          _results.push(this.collection(a));
        }
        return _results;
      };

      return Router;

    })(Cartograph);
  });

  namespace("Lib.StatefulWidget", function() {
    var StatefulWidget;
    return StatefulWidget = (function(_super) {
      __extends(StatefulWidget, _super);

      StatefulWidget.extendAndInclude(Submachine);

      StatefulWidget.extendAndInclude(EventSpitter);

      StatefulWidget.onEnter("*", function() {
        this.$el.addClass(this.state);
        return this.emit("enterState:" + this.state);
      });

      StatefulWidget.onLeave("*", function() {
        this.$el.removeClass(this.state);
        return this.emit("leaveState:" + this.state);
      });

      function StatefulWidget(selector) {
        var _ref;
        if (this._uid == null) {
          this._uid = this._generateUID();
        }
        this.$el = $(selector);
        this.el = this.$el[0];
        if (((_ref = this._states) != null ? _ref[0] : void 0) != null) {
          this.initState(this._states[0]);
        }
        this._bindEvents();
      }

      StatefulWidget.prototype.unbind = function() {
        this.$el.off("." + this._uid);
        return this.off();
      };

      StatefulWidget.prototype._bindEvents = function() {
        var item, _i, _len, _ref, _results;
        if (!this._event_map) {
          return false;
        }
        _ref = this._event_map;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          item = _ref[_i];
          _results.push((function(_this) {
            return function(item) {
              var args;
              args = ["" + item.event + "." + _this._uid];
              if (item.target != null) {
                args.push(item.target);
              }
              if (typeof item.fn === "string") {
                args.push(_this._boundInstanceMethod(item.fn));
              } else {
                args.push(item.fn);
              }
              return _this.$el.on.apply(_this.$el, args);
            };
          })(this)(item));
        }
        return _results;
      };

      StatefulWidget.prototype._boundInstanceMethod = function(name) {
        return (function(_this) {
          return function() {
            var args;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            return _this[name].apply(_this, args);
          };
        })(this);
      };

      StatefulWidget.prototype._generateUID = function() {
        return StatefulWidget.nextUID();
      };

      StatefulWidget.nextUID = function() {
        if (this._uid_counter == null) {
          this._uid_counter = 0;
        }
        this._uid_counter += 1;
        return "widget_" + this._uid_counter;
      };

      StatefulWidget.mapEvent = function(evt, fn) {
        var map, str, target, _base, _ref;
        if ((_base = this.prototype)._event_map == null) {
          _base._event_map = [];
        }
        if (!this.prototype.hasOwnProperty("_event_map")) {
          this.prototype._event_map = this.prototype._event_map.slice(0);
        }
        _ref = /([^\s]*)\s*(.*)/.exec(evt), str = _ref[0], evt = _ref[1], target = _ref[2];
        map = {
          event: evt,
          fn: fn
        };
        if ((target != null ? target.length : void 0) > 0) {
          map.target = target;
        }
        return this.prototype._event_map.push(map);
      };

      StatefulWidget.mapEvents = function(map) {
        var evt, fn, _results;
        _results = [];
        for (evt in map) {
          fn = map[evt];
          _results.push(this.mapEvent(evt, fn));
        }
        return _results;
      };

      StatefulWidget.events = StatefulWidget.prototype.mapEvents;

      return StatefulWidget;

    })(Lib.Module);
  });

  I18n = (function() {
    var resolve;

    function I18n() {}

    I18n.translate = function(key, obj) {
      var key_segments, regexp, translation, value;
      if (obj == null) {
        obj = {};
      }
      translation = resolve(window.Translations, key);
      if (translation != null) {
        for (key in obj) {
          value = obj[key];
          regexp = new RegExp("%\\{\\s*" + key + "\\s*\\}");
          translation = translation.replace(regexp, value);
        }
      } else if (obj["default"] != null) {
        translation = obj["default"];
        for (key in obj) {
          value = obj[key];
          regexp = new RegExp("%\\{\\s*" + key + "\\s*\\}");
          translation = translation.replace(regexp, value);
        }
      } else {
        key_segments = key.split(".");
        translation = key_segments[key_segments.length - 1].replace("_", " ");
      }
      return translation;
    };

    I18n.t = I18n.translate;

    resolve = function(obj, key) {
      var key_copy, path, segments, value;
      if (obj == null) {
        return null;
      }
      key_copy = key + "";
      value = null;
      path = [];
      while (key_copy.length && !(value = obj[key_copy])) {
        segments = key_copy.split(".");
        path.push(segments.pop());
        key_copy = segments.join(".");
      }
      while ((value != null) && path.length > 0) {
        value = value[path.pop()];
      }
      return value;
    };

    return I18n;

  })();

  this.I18n = I18n;

  this.t = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return I18n.t.apply(I18n, args);
  };

  BaseValidator = (function(_super) {
    __extends(BaseValidator, _super);

    function BaseValidator(attr, opts) {
      var key, val;
      this.options = {};
      for (key in opts) {
        val = opts[key];
        this.options[key] = val;
      }
    }

    BaseValidator.prototype.validate = function(obj) {
      var condition;
      if (this.options["if"] == null) {
        return this.run(obj);
      }
      if (typeof this.options["if"] === "string") {
        condition = obj[this.options["if"]];
      } else {
        condition = this.options["if"];
      }
      if (condition.call(obj) === true) {
        return this.run(obj);
      }
    };

    BaseValidator.prototype.run = function() {
      throw "'run' method has to be implemented by BaseValidator subclasses";
    };

    return BaseValidator;

  })(Lib.Module);

  PresenceValidator = (function(_super) {
    __extends(PresenceValidator, _super);

    function PresenceValidator(attr, opts) {
      var _base;
      if (opts === true) {
        opts = {};
      }
      PresenceValidator.__super__.constructor.call(this, attr, opts);
      this.attribute = attr;
      if ((_base = this.options).message == null) {
        _base.message = I18n.t("errors.messages.empty");
      }
    }

    PresenceValidator.prototype.run = function(obj) {
      var value;
      value = obj.get(this.attribute);
      if (!((value != null) && (value + "").length > 0)) {
        return obj.addError(this.attribute, this.options.message);
      }
    };

    return PresenceValidator;

  })(BaseValidator);

  FormatValidator = (function(_super) {
    __extends(FormatValidator, _super);

    function FormatValidator(attr, opts) {
      var _base;
      FormatValidator.__super__.constructor.call(this, attr, opts);
      this.attribute = attr;
      if ((_base = this.options).message == null) {
        _base.message = I18n.t("errors.messages.invalid");
      }
    }

    FormatValidator.prototype.run = function(obj) {
      var value;
      value = obj.get(this.attribute);
      if (!((value != null) && (value + "").length > 0 && (this.options["with"] != null))) {
        return;
      }
      if (!this.options["with"].test(value)) {
        return obj.addError(this.attribute, this.options.message);
      }
    };

    return FormatValidator;

  })(BaseValidator);

  RangeValidator = (function(_super) {
    __extends(RangeValidator, _super);

    function RangeValidator(attr, opts) {
      var _base;
      RangeValidator.__super__.constructor.call(this, attr, opts);
      this.attribute = attr;
      if ((_base = this.options).message == null) {
        _base.message = I18n.t("errors.messages.not_in_range");
      }
    }

    RangeValidator.prototype.run = function(obj) {
      var value;
      value = obj.get(this.attribute);
      if (!((value != null) && (value + "").length > 0 && ((this.options.max != null) || (this.options.min != null)))) {
        return;
      }
      if ((this.options.min != null) && typeof this.options.min === "function") {
        this.options.min = this.options.min.call(obj);
      }
      if ((this.options.max != null) && typeof this.options.max === "function") {
        this.options.max = this.options.max.call(obj);
      }
      if ((this.options.min != null) && typeof this.options.min === "object" && this.options.min._isAMomentObject && !value.min(this.options.min)) {
        return obj.addError(this.attribute, this.options.message);
      } else if ((this.options.max != null) && typeof this.options.max === "object" && this.options.max._isAMomentObject && !value.max(this.options.max)) {
        return obj.addError(this.attribute, this.options.message);
      } else if ((this.options.min != null) && value < this.options.min) {
        return obj.addError(this.attribute, this.options.message);
      } else if ((this.options.max != null) && value > this.options.max) {
        return obj.addError(this.attribute, this.options.message);
      }
    };

    return RangeValidator;

  })(BaseValidator);

  AcceptanceValidator = (function(_super) {
    __extends(AcceptanceValidator, _super);

    function AcceptanceValidator(attr, opts) {
      var _base, _base1;
      AcceptanceValidator.__super__.constructor.call(this, attr, opts);
      this.attribute = attr;
      if ((_base = this.options).message == null) {
        _base.message = I18n.t("errors.messages.accepted");
      }
      if ((_base1 = this.options).accept == null) {
        _base1.accept = "1";
      }
    }

    AcceptanceValidator.prototype.run = function(obj) {
      if (obj.get(this.attribute) !== this.options.accept) {
        return obj.addError(this.attribute, this.options.message);
      }
    };

    return AcceptanceValidator;

  })(BaseValidator);

  LengthValidator = (function(_super) {
    __extends(LengthValidator, _super);

    function LengthValidator(attr, opts) {
      var _base, _base1, _base2;
      LengthValidator.__super__.constructor.call(this, attr, opts);
      this.attribute = attr;
      if ((_base = this.options).too_long == null) {
        _base.too_long = I18n.t("errors.messages.too_long.other");
      }
      if ((_base1 = this.options).too_short == null) {
        _base1.too_short = I18n.t("errors.messages.too_short.other");
      }
      if ((_base2 = this.options).wrong_length == null) {
        _base2.wrong_length = I18n.t("errors.messages.wrong_length.other");
      }
    }

    LengthValidator.prototype.run = function(obj) {
      var value;
      value = "" + (obj.get(this.attribute));
      if (value == null) {
        return;
      }
      if ((this.options.max != null) && value.length > this.options.max) {
        obj.addError(this.attribute, this.options.too_long);
      }
      if ((this.options.min != null) && value.length < this.options.min) {
        obj.addError(this.attribute, this.options.too_short);
      }
      if ((this.options.is != null) && value.length !== this.options.is) {
        return obj.addError(this.attribute, this.options.wrong_length);
      }
    };

    return LengthValidator;

  })(BaseValidator);

  namespace("Lib.Validators", function() {
    return {
      BaseValidator: BaseValidator,
      PresenceValidator: PresenceValidator,
      FormatValidator: FormatValidator,
      AcceptanceValidator: AcceptanceValidator,
      RangeValidator: RangeValidator,
      LengthValidator: LengthValidator
    };
  });

  namespace("Lib.URLBuilder", function() {
    return {
      buildURL: function(template, params, options) {
        var path, querystr, re;
        if (options == null) {
          options = {};
        }
        params = $.extend({}, params);
        re = /:([\w\d]+)/g;
        path = template.replace(re, function(match, name) {
          var value;
          value = encodeURIComponent(params[name]);
          delete params[name];
          return value;
        });
        if (options.querystring === false) {
          return path;
        }
        querystr = $.param(params);
        if (querystr.length > 0) {
          if (/\?/.test(path)) {
            querystr = "&" + querystr;
          } else {
            querystr = "?" + querystr;
          }
        }
        return "" + path + querystr;
      }
    };
  });

}).call(this);
