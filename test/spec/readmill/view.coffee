describe "View", ->
  jQuery = Annotator.$
  View   = Annotator.Readmill.View
  view   = null

  beforeEach ->
    view = new View
    sinon.stub(view, "publish")

  it "should be an instance of Annotator.Class", ->
    expect(view).to.be.an.instanceof Annotator.Class

  it "should have a @element containing a <div>", ->
    expect(view.element.get(0).tagName).to.equal("DIV")

  describe "#isPrivate()", ->
    it "should return false if the checkbox is checked", ->
      expect(view.isPrivate()).to.equal(false)

    it "should return true if the checkbox is checked", ->
      view.element.find("input").attr("checked", "checked")
      expect(view.isPrivate()).to.equal(true)

  describe "#connect()", ->
    it "should publish the \"connect\" event", ->
      view.connect()
      expect(view.publish).was.called()
      expect(view.publish).was.calledWith("connect")

  describe "#reading()", ->
    it "should update the connect button", ->
      target = sinon.stub(view, "updateState")
      view.reading()
      expect(target).was.called()
      expect(target).was.calledWith(view.states.FINISH_READING)

    it "should publish the \"reading\" event", ->
      view.reading()
      expect(view.publish).was.called()
      expect(view.publish).was.calledWith("reading")

  describe "#finish()", ->
    beforeEach ->
      sinon.stub(view, "login")

    it "should reset the view to login state", ->
      view.finish()
      expect(view.login).was.called()

    it "should publish the \"reading\" event", ->
      view.finish()
      expect(view.publish).was.called()
      expect(view.publish).was.calledWith("finish")

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

      expect(el.find(".annotator-readmill-avatar").attr("href")).to.equal(user.permalink_url)
      expect(el.find(".annotator-readmill-avatar").attr("title")).to.equal("#{user.fullname} (#{user.username})")
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

  describe "updateState()", ->
    it "should update the hash and html of the connect link", ->
      target = view.element.find(".annotator-readmill-connect a")
      map = {}
      map[view.states.CONNECT]        = "Connect With Readmill…"
      map[view.states.START_READING]  = "Begin Reading…"
      map[view.states.FINISH_READING] = "Finish Reading…"

      for key, state of view.states
        view.updateState(state)
        expect(target[0].hash).to.equal("#" + state)
        expect(target.html()).to.equal(map[state])

  describe "#updatePrivate()", ->
    it "should add the @classes.private class if isPrivate is true"
    it "should remove the @classes.private class if isPrivate is false"
    it "should check the checkbox if isPrivate is true"
    it "should uncheck the checkbox if isPrivate is false"
    it "should do nothing if the checkbox state is unchanged"
    it "should allow options.force to bypass the check"
    it "should trigger the \"private\" event"

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
      event.target = {hash: "#connect"}
      sinon.stub(event, "preventDefault")
      sinon.stub(view, "connect")

    it "should call @connect() if the hash equals #connect", ->
      view._onConnectClick(event)
      expect(view.connect).was.called()

    it "should call @reading() if the hash equals #start", ->
      event.target.hash = "#start"
      target = sinon.stub(view, "reading")
      view._onConnectClick(event)
      expect(target).was.called()

    it "should call @login() if the hash equals #finish", ->
      sinon.stub(window, "confirm").returns(true)
      event.target.hash = "#finish"
      target = sinon.stub(view, "login")
      view._onConnectClick(event)
      expect(target).was.called()
      window.confirm.restore()

    it "should prevent the default browser action", ->
      view._onConnectClick(event)
      expect(event.preventDefault).was.called()

  describe "#_onLogoutClick()", ->
    event = null

    beforeEach ->
      event = jQuery.Event()
      sinon.stub(event, "preventDefault")
      sinon.stub(view, "disconnect")

    it "should call @disconnect()", ->
      view._onLogoutClick(event)
      expect(view.disconnect).was.called()

    it "should prevent the default browser action", ->
      view._onLogoutClick(event)
      expect(event.preventDefault).was.called()

  describe "#_onCheckboxChange()", ->
    event = null

    beforeEach ->
      event = jQuery.Event()
      event.target = checked: true

    it "should update the private checkbox state", ->
      sinon.stub(view, "updatePrivate")
      view._onCheckboxChange(event)
      target = view.element.find('label').hasClass(view.classes.checked)
      expect(view.updatePrivate).was.called()
      expect(view.updatePrivate).was.calledWith(true)

    it "should add @classes.checked to the label is checked", ->
      view._onCheckboxChange(event)
      target = view.element.find('label').hasClass(view.classes.checked)
      expect(target).to.equal(true)

    it "should remove @classes.checked to the label is not checked", ->
      event.target.checked = false
      view._onCheckboxChange(event)
      target = view.element.find('label').hasClass(view.classes.checked)
      expect(target).to.equal(false)

    it "should publish the \"privacy\" event", ->
      view._onCheckboxChange(event)
      expect(view.publish).was.called()
      expect(view.publish).was.calledWith("privacy", [true, view])


