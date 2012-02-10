# View class for rendering the plugin badge that allows the user to login and
# logout of the Readmill service as well as display the current book.
#
# This instance will publish various events when the user interacts with the
# badge. These can be listened for using the @subscribe()/@on() methods.
#
# Examples
#
#   view = new View
#   jQuery("body").append view.render
#
#   view.updateBook(book)
#   view.on "connect",    -> view.login(user)
#   view.on "disconnect", -> view.logout()
#
# Returns a new instance of View.
Annotator.Readmill.View = class View extends Annotator.Class
  jQuery = Annotator.$

  # Map of events/handlers to be bound to @element.
  events:
    ".annotator-readmill-connect a click": "_onConnectClick"
    ".annotator-readmill-logout a click":  "_onLogoutClick"
    "input[type=checkbox] change":         "_onCheckboxChange"

  states:
    CONNECT:        "connect"
    START_READING:  "start"
    NOW_READING:    "reading"

  # Classes used to manipulate view state.
  classes:
    checked:  "annotator-readmill-checked"
    reading:  "annotator-readmill-reading"
    loggedIn: "annotator-readmill-logged-in"

  # Template string for the inner html of the view.
  template: """
  <a class="annotator-readmill-avatar" target="_blank">
    <img />
  </a>
  <div class="annotator-readmill-reading">
    <a class="annotator-readmill-book" target="_blank"></a>
    <input type="checkbox" id="annotator-readmill-private-reading" />
    <label for="annotator-readmill-private-reading">Private Reading</label>
  </div>
  <div class="annotator-readmill-connect">
    <a href="#connect">Connect with Readmill</a>
  </div>
  <div class="annotator-readmill-logout">
    <a href="#">Log Out</a>
  </div>
  """

  # Public: Creates a new instance of the view class and creates the @element
  # property which is a jQuery wrapper around the root View element.
  #
  # Returns nothing.
  constructor: ->
    super jQuery("<div class=\"annotator-readmill\"/>").html(@template)

  # Public: Checks to see if the user has clicked the "privacy" button.
  #
  # Examples
  #
  #   setPrivateReading() if view.private()
  #
  # Returns true if the checkbox is checked.
  isPrivate: ->
    @element.find("input[type=checkbox]")[0].checked

  # Public: Triggers the "connect" event passing in the View instance to
  # all registered listeners. This is called when the user wishes to
  # connect with the Readmill service. The implmentor should then call
  # @login() once the user has authenticated and the user object has been
  # retrieved from the server.
  #
  # options - An object literal of method options.
  #           silent - If true the method will not publish any events.
  #
  # Examples
  #
  #   view.connect()
  #
  # Returns itself.
  connect: (options={}) ->
    @publish "connect", [this] unless options.silent
    this

  # Public: Triggers the "disconnect" event passing in the View instance to
  # all registered listeners. This is called when the user wishes to
  # logout of the Readmill service. The implmentor should then call
  # @logout() once the user has been logged out from Readmill.
  #
  # options - An object literal of method options.
  #           silent - If true the method will not publish any events.
  #
  # Examples
  #
  #   view.disconnect()
  #
  # Returns itself.
  disconnect: (options={}) ->
    @publish "disconnect", [this] unless options.silent
    this

  # Public: Updates the view to the "logged in" state. Showing the log out
  # button and user details. This should be called once the user has been
  # authenticated with the Readmill service.
  #
  # Publishes the "login" event once the view has updated.
  #
  # user    - The user object retrieved from Readmill.
  # options - An object literal of method options.
  #           silent - If true the method will not publish any events.
  #
  # Examples
  #
  #   user = getLoggedInUser()
  #   view.login user
  #
  # Returns itself.
  login: (user, options={}) ->
    @updateUser(user) if user
    @updateState(@states.START_READING)
    @element.addClass @classes.loggedIn
    @publish("login", [this]) unless options.silent
    this

  # Public: Switches the current view state to reading. This should be called
  # once the user decides to start a reading session.
  #
  # Publishes the "reading" event once the view has updated.
  #
  # options - An object literal of method options.
  #           silent - If true the method will not publish any events.
  #
  # Returns itself.
  reading: (options={}) ->
    @updateState(@states.NOW_READING)
    @publish("reading", [this]) unless options.silent
    this

  # Public: Switches the current view state to "finish". This should be called
  # once a user decides to end a reading session.
  #
  # Publishes the "finish" event once the view has updated.
  #
  # options - An object literal of method options.
  #           silent - If true the method will not publish any events.
  #
  # param - comment
  #
  # Returns itself.
  finish: (options={}) ->
    @publish("finish", [this]) unless options.silent
    @login()
    this

  # Public: Updates the view to the "logged out" state. Showing the connect
  # button. This should be called if the accessToken expires or the user
  # manually logs out.
  #
  # Publishes the "logout" event once the view has updated.
  #
  # options - An object literal of method options.
  #           silent - If true the method will not publish any events.
  #
  # Examples
  #
  #   view.on "disconnect" ->
  #     view.logout()
  #
  # Returns itself.
  logout: (options={}) ->
    @element.removeClass(@classes.loggedIn).html(@template)

    @user = null
    @updateBook()

    @publish("logout", [this]) unless options.silent
    this

  # Public: Updates the user elements within the view. Will update the @user
  # property or simply use the current value. This method will not transition
  # the view to the logged in state.
  #
  # user - A user object (deafult: @user).
  #
  # Returns itself.
  updateUser: (@user=@user) ->
    if @user
      attrs = 
        href: @user.permalink_url
        title: "#{@user.fullname} (#{@user.username})"

      @element.find(".annotator-readmill-avatar").attr(attrs)
              .find("img").attr("src", @user.avatar_url)
    this

  # Public: Updates the portion of the view that display book information.
  # Also updates the @book property.
  #
  # book - A book object (default: @book).
  #
  # Examples
  #
  #   book = getBook()
  #   view.updateBook book
  #
  # Returns itself.
  updateBook: (@book=@book) ->
    text = "Loading book…"
    target = @element.find(".annotator-readmill-book")
    if @book
      text = @book.title if @book.title
      if @book.reading
        @updatePrivate(@book.reading.private)
        target.attr("href", @book.reading.permalink_url)
    target.escape(text)
    this

  # Internal: Updates the current reading state.
  #
  # state - One of the @states constants.
  #
  # Returns itself.
  updateState: (state) ->
    map = {}
    map[@states.CONNECT]        = "Connect With Readmill&hellip;"
    map[@states.START_READING]  = "Begin Reading&hellip;"
    map[@states.NOW_READING] = "Now Reading&hellip;"

    @element.find(".annotator-readmill-connect a").html(map[state])
            .attr("href", "#" + state)
    this

  # Public: Toggles the privacy checkbox.
  #
  # isPrivate - True if the checkbox should be checked (default: false).
  # options   - Object literal of options for the method (default: {}).
  #             force: Force an update, useful for updating the rest of the
  #                    view when the checkbox changes.
  #
  # Examples
  #
  #   view.updatePrivate(true) # Check the checkbox
  #   view.updatePrivate(false) # Check the checkbox
  #   view.updatePrivate(false, force: true) # Force an update
  #
  # Returns itself.
  updatePrivate: (isPrivate=false, options={}) ->
    if isPrivate isnt @isPrivate() or options.force is true
      @element.find("label").toggleClass(@classes.checked, isPrivate)
      @element.find("input[type=checkbox]")[0].checked = isPrivate
      @publish "privacy", [isPrivate, this]
    this

  # Public: Renders the full view. Should be called once the instance is
  # created just before/after it is appended to the document.
  #
  # Examples
  #
  #   jQuery("body").append view.render()
  #
  # Returns the @element property.
  render: ->
    @updateBook()
    @updateUser()
    @element

  # Callback for click events on the "connect" button.
  #
  # event - A mouse jQuery.Event object.
  #
  # Returns nothing.
  _onConnectClick: (event) =>
    event.preventDefault()
    switch event.target.hash.slice(1)
     when @states.CONNECT then @connect()
     when @states.START_READING then @reading()

  # Callback for click events on the "logout" button.
  #
  # event - A mouse jQuery.Event object.
  #
  # Returns nothing.
  _onLogoutClick: (event) =>
    event.preventDefault()
    @disconnect()
    @logout()

  # Callback event for the privacy checkbox. Triggers the "privacy" event
  # passing in true to all callbacks if the checkbox is checked.
  #
  # event - A jQuery.Event change event.
  #
  # Returns nothing.
  _onCheckboxChange: (event) =>
    @updatePrivate(event.target.checked, force: true)
