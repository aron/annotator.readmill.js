(function() {
  var Readmill;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Readmill = (function() {
    __extends(Readmill, Annotator.Plugin);
    function Readmill() {
      Readmill.__super__.constructor.apply(this, arguments);
    }
    Readmill.CLIENT_ID = "454f5cfd1e794930c6fa99a94faad810";
    Readmill.API_ENDPOINT = "http://localhost:8000";
    return Readmill;
  })();
  Readmill.utils = {
    serializeQueryString: function(obj, sep, eq) {
      var esc, key, value;
      if (sep == null) {
        sep = "&";
      }
      if (eq == null) {
        eq = "=";
      }
      esc = window.encodeURIComponent;
      return ((function() {
        var _results;
        _results = [];
        for (key in obj) {
          if (!__hasProp.call(obj, key)) continue;
          value = obj[key];
          _results.push("" + (esc(key)) + eq + (esc(value)));
        }
        return _results;
      })()).join(sep);
    },
    parseQueryString: function(str, sep, eq) {
      var decode, key, obj, param, value, _i, _len, _ref, _ref2;
      if (sep == null) {
        sep = "&";
      }
      if (eq == null) {
        eq = "=";
      }
      obj = {};
      decode = window.decodeURIComponent;
      _ref = str.split(sep);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        param = _ref[_i];
        _ref2 = param.split(eq), key = _ref2[0], value = _ref2[1];
        obj[decode(key)] = decode(value);
      }
      return obj;
    }
  };
  Readmill.Auth = (function() {
    Auth.AUTH_ENDPOINT = "http://localhost:8000/oauth/authorize";
    function Auth(options) {
      this.callback = __bind(this.callback, this);      this.clientId = options.clientId, this.callbackUri = options.callbackUri, this.authEndpoint = options.authEndpoint;
      if (!this.authEndpoint) {
        this.authEndpoint = Readmill.Auth.AUTH_ENDPOINT;
      }
    }
    Auth.prototype.connect = function() {
      var params, qs;
      params = {
        response_type: "code",
        client_id: this.clientId,
        redirect_uri: this.callbackUri
      };
      qs = Readmill.utils.serializeQueryString(params);
      Readmill.Auth.callback = this.callback;
      this.popup = this.openWindow("" + this.authEndpoint + "?" + qs);
      this.deferred = new jQuery.Deferred();
      return this.deferred.promise();
    };
    Auth.prototype.callback = function() {
      var hash, params, qs;
      hash = this.popup.location.hash.slice(1);
      params = qs = Readmill.utils.parseQueryString(hash);
      this.popup.close();
      if (params.access_token) {
        return this.deferred.resolve(params);
      } else {
        return this.deferred.reject(params.error);
      }
    };
    Auth.prototype.openWindow = function(url, width, height) {
      var left, paramString, params, top;
      if (width == null) {
        width = 725;
      }
      if (height == null) {
        height = 575;
      }
      left = window.screenX + (window.outerWidth - width) / 2;
      top = window.screenY + (window.outerHeight - height) / 2;
      params = {
        toolbar: false,
        location: 1,
        scrollbars: true,
        top: top,
        left: left,
        width: width,
        height: height
      };
      paramString = Readmill.utils.serializeQueryString(params, ",");
      return window.open(url, "readmill-connect", paramString);
    };
    return Auth;
  })();
  window.Annotator.Plugin.Readmill = Readmill;
}).call(this);
