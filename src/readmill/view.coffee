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
    FINISH_READING: "finish"

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
  # Examples
  #
  #   view.connect()
  #
  # Returns itself.
  connect: ->
    @publish "connect", [this]

  # Public: Triggers the "disconnect" event passing in the View instance to
  # all registered listeners. This is called when the user wishes to
  # logout of the Readmill service. The implmentor should then call
  # @logout() once the user has been logged out from Readmill.
  #
  # Examples
  #
  #   view.disconnect()
  #
  # Returns itself.
  disconnect: ->
    @publish "disconnect", [this]

  # Public: Updates the view to the "logged in" state. Showing the log out
  # button and user details. This should be called once the user has been
  # authenticated with the Readmill service.
  #
  # Publishes the "login" event once the view has updated.
  #
  # user - The user object retrieved from Readmill.
  #
  # Examples
  #
  #   user = getLoggedInUser()
  #   view.login user
  #
  # Returns itself.
  login: (user) ->
    @updateUser(user) if user
    @updateState(@states.START_READING)
    @element.addClass @classes.loggedIn
    @publish "login", [this]

  # Public: Switches the current view state to reading. This should be called
  # once the user decides to start a reading session.
  #
  # Publishes the "reading" event once the view has updated. Passes true as the
  # first argument to all callbacks if the reading is private.
  #
  # isPrivate - True if the user has determined this a private reading session.
  #
  # Returns itself.
  reading: ->
    @updateState(@states.FINISH_READING)
    @publish "reading", [this]

  # Public: Updates the view to the "logged out" state. Showing the connect
  # button. This should be called if the accessToken expires or the user
  # manually logs out.
  #
  # Publishes the "logout" event once the view has updated.
  #
  # Examples
  #
  #   view.on "disconnect" ->
  #     view.logout()
  #
  # Returns itself.
  logout: ->
    @element.removeClass(@classes.loggedIn).html(@template)

    @user = null
    @updateBook()

    @publish "logout", [this]

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
      link = if @book.reading then @book.reading.permalink_url
      target.attr("href", link) if link
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
    map[@states.FINISH_READING] = "Finish Reading&hellip;"

    @element.find(".annotator-readmill-connect a").html(map[state])
            .attr("href", "#" + state)
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
     when @states.FINISH_READING then @login()

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
    @element.find("label").toggleClass(@classes.checked, event.target.checked)
    @publish "privacy", [event.target.checked, this]
