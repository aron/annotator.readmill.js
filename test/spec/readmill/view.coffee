describe "View", ->
  jQuery = Annotator.$
  View   = Annotator.Readmill.View
  view   = null

  beforeEach ->
    view = new View
    sinon.stub(view, "publish")


  it "should be an instance of View", ->
    expect(view).to.be.an.instanceof View

  it "should have a @element containing a <div>", ->
    expect(view.element.get(0).tagName).to.equal("DIV")

  describe "#connect()", ->
    it "should publish the \"connect\" event", ->
      view.connect()
      expect(view.publish).was.called()
      expect(view.publish).was.calledWith("connect")

  describe "#disconnect()", ->
    it "should publish the \"disconnect\" event", ->
      view.disconnect()
      expect(view.publish).was.called()
      expect(view.publish).was.calledWith("disconnect")

  describe "#login()", ->
    beforeEach ->
      sinon.stub view, "updateUser"

    it "should call @updateUser if a user object is provided", ->
      user = name: "Bill"
      view.login(user)
      expect(view.updateUser).was.called()
      expect(view.updateUser).was.calledWith(user)

    it "should not call @updateUser if a user object is not provided", ->
      view.login()
      expect(view.updateUser).was.notCalled()

    it "should add the @classes.loggedIn class to the @element", ->
      view.login()
      expect(view.element[0].className).to.include(view.classes.loggedIn)

    it "should publish the \"login\" event", ->
      view.login()
      expect(view.publish).was.called()
      expect(view.publish).was.calledWith("login")

  describe "#logout()", ->
    beforeEach ->
      sinon.stub view, "updateBook"
      sinon.stub view.element, "html"

    it "should remove the @classes.loggedIn class from the @element", ->
      view.element.addClass(view.classes.loggedIn)
      view.logout()
      expect(view.element[0].className).not.to.include(view.classes.loggedIn)

    it "should reset the template", ->
      view.logout()
      expect(view.element.html).was.called()
      expect(view.element.html).was.calledWith(view.template)

    it "should reset the @user object", ->
      view.user = {}
      view.logout()
      expect(view.user).to.equal(null)

    it "should call @updateBook", ->
      view.logout()
      expect(view.updateBook).was.called()

    it "should publish the \"logout\" event", ->
      view.logout()
      expect(view.publish).was.called()
      expect(view.publish).was.calledWith("logout")

  describe "#updateUser()", ->
    user =
      fullname: "Aron Carroll"
      username: "aron"
      permalink_url: "http://readmill.com/aron"
      avatar_url: "http://readmill.com/aron.png"

    it "should set the @user property", ->
      view.updateUser(user)
      expect(view.user).to.equal(user)

    it "should update the appropriate DOM elements", ->
      el = view.element
      view.updateUser(user)

      expect(el.find(".annotator-readmill-fullname").html()).to.equal(user.fullname)
      expect(el.find(".annotator-readmill-username").html()).to.equal(user.username)
      expect(el.find(".annotator-readmill-avatar").attr("href")).to.equal(user.permalink_url)
      expect(el.find(".annotator-readmill-avatar img").attr("src")).to.equal(user.avatar_url)

  describe "#updateBook()", ->
    it "should set the @book property", ->
      book = {title: "Title"}
      view.updateBook(book)
      expect(view.book).to.equal(book)

    it "should update the appropriate DOM elements", ->
      el = view.element
      view.updateBook(title: "Title")
      expect(el.find(".annotator-readmill-book").html()).to.equal("Title")

    it "should show a loading message if no title", ->
      el = view.element
      view.updateBook()
      expect(el.find(".annotator-readmill-book").html()).to.equal("Loading book…")

  describe "#render()", ->
    it "should call @updateBook()", ->
      sinon.stub view, "updateBook"
      view.render()
      expect(view.updateBook).was.called()

    it "should call @updateUser()", ->
      sinon.stub view, "updateUser"
      view.render()
      expect(view.updateUser).was.called()

    it "should return the @element property", ->
      expect(view.render()).to.equal(view.element)

  describe "#_onConnectClick()", ->
    event = null

    beforeEach ->
      event = jQuery.Event()
      sinon.stub(event, "preventDefault")
      sinon.stub(view, "connect")

    it "should call @connect()", ->
      view._onConnectClick(event)
      expect(view.connect).was.called()

    it "should prevent the default browser action", ->
      view._onConnectClick(event)
      expect(event.preventDefault).was.called()

  describe "#_onUpdateClick()", ->
    event = null

    beforeEach ->
      event = jQuery.Event()
      sinon.stub(event, "preventDefault")
      sinon.stub(view, "disconnect")

    it "should call @disconnect()", ->
      view._onLogoutClick(event)
      expect(view.disconnect).was.called()

    it "should prevent the default browser action", ->
      view._onConnectClick(event)
      expect(event.preventDefault).was.called()

