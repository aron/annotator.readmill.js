(function() {
  var Auth, Client, Readmill, Store, View, jQuery, utils;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  jQuery = Annotator.$;
  Readmill = (function() {
    __extends(Readmill, Annotator.Plugin);
    Readmill.API_ENDPOINT = "http://localhost:8000";
    Readmill.prototype.events = {
      "annotationCreated": "_onAnnotationCreated",
      "annotationUpdated": "_onAnnotationUpdated",
      "annotationDeleted": "_onAnnotationDeleted"
    };
    function Readmill(options) {
      this._onAnnotationDeleted = __bind(this._onAnnotationDeleted, this);
      this._onAnnotationUpdated = __bind(this._onAnnotationUpdated, this);
      this._onAnnotationCreated = __bind(this._onAnnotationCreated, this);
      this._onGetHighlightsError = __bind(this._onGetHighlightsError, this);
      this._onGetHighlightsSuccess = __bind(this._onGetHighlightsSuccess, this);
      this._onGetReadingError = __bind(this._onGetReadingError, this);
      this._onGetReadingSuccess = __bind(this._onGetReadingSuccess, this);
      this._onCreateReadingError = __bind(this._onCreateReadingError, this);
      this._onCreateReadingSuccess = __bind(this._onCreateReadingSuccess, this);
      this._onBookError = __bind(this._onBookError, this);
      this._onBookSuccess = __bind(this._onBookSuccess, this);
      this._onMeError = __bind(this._onMeError, this);
      this._onMeSuccess = __bind(this._onMeSuccess, this);
      this._onConnectError = __bind(this._onConnectError, this);
      this._onConnectSuccess = __bind(this._onConnectSuccess, this);
      this.disconnect = __bind(this.disconnect, this);
      this.connect = __bind(this.connect, this);      var token;
      Readmill.__super__.constructor.apply(this, arguments);
      this.user = null;
      this.book = this.options.book;
      this.view = new Readmill.View;
      this.auth = new Readmill.Auth(this.options);
      this.store = new Readmill.Store;
      this.client = new Readmill.Client(this.options);
      this.view.subscribe("connect", this.connect);
      this.view.subscribe("disconnect", this.disconnect);
      token = options.accessToken || this.store.get("access-token");
      if (token) {
        this.connected(token, {
          silent: true
        });
      }
      this.unsaved = [];
    }
    Readmill.prototype.pluginInit = function() {
      jQuery("body").append(this.view.render());
      return this.lookupBook().done;
    };
    Readmill.prototype.lookupBook = function() {
      if (this.book.deferred) {
        return this.book.deferred;
      }
      this.book.deferred = this.book.id ? this.client.getBook(this.book.id) : this.client.matchBook(this.book);
      return this.book.deferred.then(this._onBookSuccess, this._onBookError).done(__bind(function() {
        return this.view.updateBook(this.book);
      }, this));
    };
    Readmill.prototype.lookupReading = function() {
      if (!this.book.id) {
        this.lookupBook();
      }
      return jQuery.when(this.book.deferred).then(__bind(function() {
        var data, request;
        data = {
          state: Readmill.Client.READING_STATE_OPEN
        };
        request = this.client.createReadingForBook(this.book.id, data);
        return request.then(this._onCreateReadingSuccess, this._onCreateReadingError);
      }, this));
    };
    Readmill.prototype.connect = function() {
      return this.auth.connect().then(this._onConnectSuccess, this._onConnectError);
    };
    Readmill.prototype.connected = function(accessToken, options) {
      this.client.authorize(accessToken);
      this.client.me().then(this._onMeSuccess, this._onMeError).done(__bind(function() {
        return this.view.login(this.user);
      }, this));
      this.store.set("access-token", accessToken, options.expires);
      if ((options != null ? options.silent : void 0) !== true) {
        return Annotator.showNotification("Successfully connected to Readmill");
      }
    };
    Readmill.prototype.disconnect = function() {
      this.client.deauthorize();
      this.store.remove("access-token");
      return this.annotator.element.find(".annotator-hl").each(function() {
        return jQuery(this).replaceWith(this.childNodes);
      });
    };
    Readmill.prototype.error = function(message) {
      return Annotator.showNotification(message, Annotator.Notification.ERROR);
    };
    Readmill.prototype._highlightFromAnnotation = function(annotation) {
      return {
        pre: JSON.stringify(annotation.ranges),
        content: annotation.quote,
        highlighted_at: void 0
      };
    };
    Readmill.prototype._commentFromAnnotation = function(annotation) {
      return {
        content: annotation.text
      };
    };
    Readmill.prototype._annotationFromHighlight = function(highlight) {
      var annotation, deferred, ranges;
      ranges = (function() {
        try {
          return JSON.parse(highlight.pre);
        } catch (e) {
          return null;
        }
      })();
      if (ranges) {
        deferred = new jQuery.Deferred();
        deferred.annotation = annotation = {
          quote: highlight.content,
          text: "",
          ranges: ranges,
          highlightUrl: highlight.uri,
          commentUrl: "",
          commentsUrl: highlight.comments
        };
        this.client.request({
          url: highlight.comments
        }).error(deferred.reject).done(function(comments) {
          if (comments.length) {
            annotation.text = comments[0].content;
            annotation.commentUrl = comments[0].uri;
          }
          return deferred.resolve(annotation);
        });
        return deferred.promise();
      } else {
        return null;
      }
    };
    Readmill.prototype._onConnectSuccess = function(params) {
      return this.connected(params.access_token, params);
    };
    Readmill.prototype._onConnectError = function(error) {
      return this.error(error);
    };
    Readmill.prototype._onMeSuccess = function(data) {
      this.user = data;
      return this.lookupReading();
    };
    Readmill.prototype._onMeError = function() {
      return this.error("Unable to fetch user info from Readmill");
    };
    Readmill.prototype._onBookSuccess = function(book) {
      return jQuery.extend(this.book, book);
    };
    Readmill.prototype._onBookError = function() {
      return this.error("Unable to fetch book info from Readmill");
    };
    Readmill.prototype._onCreateReadingSuccess = function(body, status, jqXHR) {
      var location, request;
      location = JSON.parse(jqXHR.responseText).location;
      if (location) {
        request = this.client.request({
          url: location,
          type: "GET"
        });
        return request.then(this._onGetReadingSuccess, this._onGetReadingError);
      } else {
        return this._onGetReadingError();
      }
    };
    Readmill.prototype._onCreateReadingError = function(jqXHR) {
      if (jqXHR.status === 409) {
        return this._onCreateReadingSuccess(null, null, jqXHR);
      }
    };
    Readmill.prototype._onGetReadingSuccess = function(reading) {
      var request;
      this.book.reading = reading;
      request = this.client.getHighlights(reading.highlights);
      return request.then(this._onGetHighlightsSuccess, this._onGetHighlightsError);
    };
    Readmill.prototype._onGetReadingError = function(reading) {
      return this.error("Unable to create reading for this book");
    };
    Readmill.prototype._onGetHighlightsSuccess = function(highlights) {
      var deferreds;
      deferreds = jQuery.map(highlights, jQuery.proxy(this, "_annotationFromHighlight"));
      deferreds = jQuery.grep(deferreds, function(def) {
        return !!def;
      });
      return jQuery.when.apply(jQuery, deferreds).done(__bind(function() {
        var annotations;
        annotations = jQuery.makeArray(arguments);
        return this.annotator.loadAnnotations(annotations);
      }, this));
    };
    Readmill.prototype._onGetHighlightsError = function() {
      return this.error("Unable to fetch highlights for reading");
    };
    Readmill.prototype._onCreateHighlight = function(annotation, data) {
      return this.client.request({
        url: data.location
      }).done(__bind(function(highlight) {
        annotation.highlightUrl = highlight.uri;
        annotation.commentsUrl = highlight.comments;
        return this.client.request({
          url: highlight.comments
        }).done(function(comments) {
          if (comments.length) {
            return annotation.commentUrl = comments[0].uri;
          }
        });
      }, this));
    };
    Readmill.prototype._onAnnotationCreated = function(annotation) {
      var comment, highlight, request, url;
      if (this.client.isAuthorized() && this.book.id) {
        url = this.book.reading.highlights;
        comment = this._commentFromAnnotation(annotation).content;
        highlight = this._highlightFromAnnotation(annotation);
        request = this.client.createHighlight(url, highlight, comment);
        return request.then(jQuery.proxy(this, "_onCreateHighlight", annotation), __bind(function() {
          return this.error("Unable to send annotation to Readmill");
        }, this));
      } else {
        this.unsaved.push(annotation);
        if (!this.client.isAuthorized()) {
          return this.connect();
        }
      }
    };
    Readmill.prototype._onAnnotationUpdated = function(annotation) {
      var data, request;
      data = this._commentFromAnnotation(annotation);
      if (annotation.commentUrl) {
        request = this.client.updateComment(annotation.commentUrl, data);
      } else if (annotation.commentsUrl) {
        request = this.client.createComment(annotation.commentsUrl, data);
        request.done(__bind(function(data) {
          return annotation.commentUrl = data.location;
        }, this));
      }
      if (request) {
        return request.fail(__bind(function(xhr) {
          return this.error("Unable to update annotation in Readmill");
        }, this));
      }
    };
    Readmill.prototype._onAnnotationDeleted = function(annotation) {
      if (annotation.highlightUrl) {
        return this.client.deleteHighlight(annotation.highlightUrl).error(__bind(function() {
          return this.error("Unable to update annotation in Readmill");
        }, this));
      }
    };
    return Readmill;
  })();
  utils = {
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
  View = (function() {
    __extends(View, Annotator.Plugin);
    View.prototype.events = {
      ".annotator-readmill-connect a click": "_onConnectClick",
      ".annotator-readmill-logout a click": "_onLogoutClick"
    };
    View.prototype.classes = {
      loggedIn: "annotator-readmill-logged-in"
    };
    View.prototype.template = "<a class=\"annotator-readmill-avatar\" href=\"\" target=\"_blank\">\n  <img src=\"\" />\n</a>\n<div class=\"annotator-readmill-user\">\n  <span class=\"annotator-readmill-fullname\"></span>\n  <span class=\"annotator-readmill-username\"></span>\n</div>\n<div class=\"annotator-readmill-book\"></div>\n<div class=\"annotator-readmill-connect\">\n  <a href=\"#\">Connect with Readmill</a>\n</div>\n<div class=\"annotator-readmill-logout\">\n  <a href=\"#\">Log Out</a>\n</div>";
    function View() {
      this._onLogoutClick = __bind(this._onLogoutClick, this);
      this._onConnectClick = __bind(this._onConnectClick, this);      View.__super__.constructor.call(this, jQuery("<div class=\"annotator-readmill\">").html(this.template));
    }
    View.prototype.connect = function() {
      return this.publish("connect", [this]);
    };
    View.prototype.login = function(user) {
      if (user) {
        this.updateUser(user);
      }
      this.element.addClass(this.classes.loggedIn);
      return this;
    };
    View.prototype.logout = function() {
      this.element.removeClass(this.classes.loggedIn).html(this.template);
      this.user = null;
      this.updateBook();
      return this.publish("disconnect", [this]);
    };
    View.prototype.updateUser = function(user) {
      this.user = user != null ? user : this.user;
      if (this.user) {
        this.element.find(".annotator-readmill-fullname").escape(this.user.fullname);
        this.element.find(".annotator-readmill-username").escape(this.user.username);
        this.element.find(".annotator-readmill-avatar").attr("href", this.user.permalink_url).find("img").attr("src", this.user.avatar_url);
      }
      return this;
    };
    View.prototype.updateBook = function(book) {
      this.book = book != null ? book : this.book;
      if (this.book) {
        this.element.find(".annotator-readmill-book").escape(this.book.title || "Loading book…");
      }
      return this;
    };
    View.prototype.render = function() {
      this.updateBook();
      this.updateUser();
      return this.element;
    };
    View.prototype._onConnectClick = function(event) {
      event.preventDefault();
      return this.connect();
    };
    View.prototype._onLogoutClick = function(event) {
      event.preventDefault();
      return this.logout();
    };
    return View;
  })();
  Client = (function() {
    Client.API_ENDPOINT = "https://api.readmill.com";
    Client.READING_STATE_INTERESTING = 1;
    Client.READING_STATE_OPEN = 2;
    Client.READING_STATE_FINISHED = 3;
    Client.READING_STATE_ABANDONED = 4;
    function Client(options) {
      this.clientId = options.clientId, this.accessToken = options.accessToken, this.apiEndpoint = options.apiEndpoint;
      if (!this.apiEndpoint) {
        this.apiEndpoint = Client.API_ENDPOINT;
      }
    }
    Client.prototype.me = function() {
      return this.request({
        url: "/me",
        type: "GET"
      });
    };
    Client.prototype.getBook = function(bookId) {
      return this.request({
        url: "/books/" + bookId,
        type: "GET"
      });
    };
    Client.prototype.matchBook = function(data) {
      return this.request({
        url: "/books/match",
        type: "GET",
        data: {
          q: data
        }
      });
    };
    Client.prototype.createBook = function(book) {
      return this.request({
        url: "/books",
        type: "POST",
        data: {
          book: book
        }
      });
    };
    Client.prototype.createReadingForBook = function(bookId, reading) {
      return this.request({
        type: "POST",
        url: "/books/" + bookId + "/readings",
        data: {
          reading: reading
        }
      });
    };
    Client.prototype.getHighlights = function(url) {
      return this.request({
        url: url,
        type: "GET"
      });
    };
    Client.prototype.getHighlight = function(url) {
      return this.request({
        url: url,
        type: "GET"
      });
    };
    Client.prototype.createHighlight = function(url, highlight, comment) {
      return this.request({
        type: "POST",
        url: url,
        data: {
          highlight: highlight,
          comment: comment
        }
      });
    };
    Client.prototype.deleteHighlight = function(url) {
      return this.request({
        type: "DELETE",
        url: url
      });
    };
    Client.prototype.createComment = function(url, comment) {
      return this.request({
        type: "POST",
        url: url,
        data: {
          comment: comment
        }
      });
    };
    Client.prototype.updateComment = function(url, comment) {
      return this.request({
        type: "PUT",
        url: url,
        data: {
          comment: comment
        }
      });
    };
    Client.prototype.request = function(options) {
      var request, xhr;
      if (options == null) {
        options = {};
      }
      xhr = null;
      if (!options.type) {
        options.type = "GET";
      }
      if (options.url.indexOf("http") !== 0) {
        options.url = "" + this.apiEndpoint + options.url;
      }
      if (options.type.toUpperCase() in {
        "POST": "POST",
        "PUT": "PUT",
        "DELETE": "DELETE"
      }) {
        options.url = "" + options.url + "?&client_id=" + this.clientId;
        if (options.data) {
          options.data = JSON.stringify(options.data);
        }
        options.dataType = "json";
        options.contentType = "application/json";
      } else {
        options.data = jQuery.extend({
          client_id: this.clientId
        }, options.data || {});
      }
      options.dataFilter = jQuery.trim;
      options.beforeSend = __bind(function(jqXHR) {
        jqXHR.setRequestHeader("X-Response", "Body");
        jqXHR.setRequestHeader("Accept", "application/json");
        if (this.accessToken) {
          return jqXHR.setRequestHeader("Authorization", "OAuth " + this.accessToken);
        }
      }, this);
      options.xhr = function() {
        return xhr = jQuery.ajaxSettings.xhr();
      };
      request = jQuery.ajax(options);
      request.xhr = xhr;
      request.getResponseHeader = function(header) {
        return xhr.getResponseHeader(header);
      };
      return request;
    };
    Client.prototype.authorize = function(accessToken) {
      this.accessToken = accessToken;
    };
    Client.prototype.deauthorize = function() {
      return this.accessToken = null;
    };
    Client.prototype.isAuthorized = function() {
      return !!this.accessToken;
    };
    return Client;
  })();
  Store = (function() {
    function Store() {}
    Store.KEY_PREFIX = "annotator.readmill/";
    Store.CACHE_DELIMITER = "--cache--";
    Store.localStorage = window.localStorage;
    Store.now = function() {
      return (new Date()).getTime();
    };
    Store.prototype.get = function(key) {
      var value;
      value = Store.localStorage.getItem(this.prefixed(key));
      if (value) {
        value = this.checkCache(value);
        if (!value) {
          this.remove(key);
        }
      }
      return JSON.parse(value);
    };
    Store.prototype.set = function(key, value, time) {
      value = JSON.stringify(value);
      if (time) {
        value = (Store.now() + time) + Store.CACHE_DELIMITER + value;
      }
      try {
        Store.localStorage.setItem(this.prefixed(key), value);
      } catch (error) {
        this.trigger('error', [error, key, value, this]);
      }
      return this;
    };
    Store.prototype.remove = function(key) {
      Store.localStorage.removeItem(this.prefixed(key));
      return this;
    };
    Store.prototype.prefixed = function(key) {
      return Store.KEY_PREFIX + key;
    };
    Store.prototype.checkCache = function(value) {
      var cached;
      if (value.indexOf(Store.CACHE_DELIMITER) > -1) {
        cached = value.split(Store.CACHE_DELIMITER);
        value = Store.now() > cached.shift() ? null : cached.join(Store.CACHE_DELIMITER);
      }
      return value;
    };
    return Store;
  })();
  Auth = (function() {
    Auth.AUTH_ENDPOINT = "http://localhost:8000/oauth/authorize";
    Auth.uuid = function() {
      if (!Auth.uuid.counter) {
        Auth.uuid.counter = 0;
      }
      return "state-" + (Auth.uuid.counter += 1);
    };
    function Auth(options) {
      this.callback = __bind(this.callback, this);      this.clientId = options.clientId, this.callbackUri = options.callbackUri, this.authEndpoint = options.authEndpoint;
      if (!this.authEndpoint) {
        this.authEndpoint = Auth.AUTH_ENDPOINT;
      }
    }
    Auth.prototype.connect = function() {
      var params, qs;
      this.deferred = new jQuery.Deferred();
      this.deferred.id = Auth.uuid();
      params = {
        response_type: "code",
        client_id: this.clientId,
        redirect_uri: this.callbackUri,
        state: this.deferred.id
      };
      qs = utils.serializeQueryString(params);
      Auth.callback = this.callback;
      this.popup = this.openWindow("" + this.authEndpoint + "?" + qs);
      return this.deferred.promise();
    };
    Auth.prototype.callback = function() {
      var hash, params, qs;
      hash = this.popup.location.hash.slice(1);
      params = qs = utils.parseQueryString(hash);
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
      paramString = utils.serializeQueryString(params, ",");
      return window.open(url, "readmill-connect", paramString);
    };
    return Auth;
  })();
  window.Annotator.Plugin.Readmill = jQuery.extend(Readmill, {
    View: View,
    Auth: Auth,
    Store: Store,
    Client: Client,
    utils: utils
  });
}).call(this);
