jQuery = Annotator.$

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
class View extends Annotator.Class
  # Map of events/handlers to be bound to @element.
  events:
    ".annotator-readmill-connect a click": "_onConnectClick"
    ".annotator-readmill-logout a click":  "_onLogoutClick"

  # Classes used to manipulate view state.
  classes:
    loggedIn: "annotator-readmill-logged-in"

  # Template string for the inner html of the view.
  template: """
  <a class="annotator-readmill-avatar" href="" target="_blank">
    <img src="" />
  </a>
  <div class="annotator-readmill-user">
    <span class="annotator-readmill-fullname"></span>
    <span class="annotator-readmill-username"></span>
  </div>
  <div class="annotator-readmill-book"></div>
  <div class="annotator-readmill-connect">
    <a href="#">Connect with Readmill</a>
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
    super jQuery("<div class=\"annotator-readmill\">").html(@template)

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
    @element.addClass @classes.loggedIn
    @publish "login", [this]

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
    el = @element
    if @user
      el.find(".annotator-readmill-fullname").escape(@user.fullname)
      el.find(".annotator-readmill-username").escape(@user.username)
      el.find(".annotator-readmill-avatar").attr("href", @user.permalink_url)
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
    text = if @book then @book.title else "Loading book…"
    @element.find(".annotator-readmill-book").escape(text)
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
    @connect()

  # Callback for click events on the "logout" button.
  #
  # event - A mouse jQuery.Event object.
  #
  # Returns nothing.
  _onLogoutClick: (event) =>
    event.preventDefault()
    @disconnect()
    @logout()
