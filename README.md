Readmill Annotator Plugin
=========================

A plugin for the [OKFN annotator][#ann] that allows you to submit highlights
and comments to [Readmill][#readmill]. It is intended for web based publishers
that want to allow thier readers to annotate their publications using Readmill
as the store.

A demo implementation can be [viewed online][#demo].

[#ann]: http://okfnlabs.org/annotator/
[#demo]: http://aron.github.com/annotator.readmill.js/
[#readmill]: http://readmill.com/

Requirements
------------

This plugin requires an account to be [created with Readmill][#developers]
and a new application to be registered. Readmill will then issue you with a
`client id` that you can use in the plugin.

Also the Readmill API does not currently support authentication using only
a browser. This means that you'll either have to manage your users access
tokens manually or host the provided proxy server yourself. This puts quite a
large overhead on installing this plugin but Readmill are working on resolving
this in the future.

[#developers]: http://readmill.com/developers

Usage
-----

Create a page on your website containing the contents of callback.html or
simply upload the file to your server. Readmill will redirect back to this
page once the user has successfully authenticated. This file must be hosted on
exactly the same domain as your annotated page.

The plugin requires the _annotator.js_ and _annotator.css_ to be included on the
page. See the annotator [Getting Started][#ann-install] guide for instructions
then simply include the _annotator.readmill.js_ and _annotator.readmill.css_
files in your page. These can be [downloaded as a zip file][#download] from
GitHub.

```html
<link rel="stylesheet" href="./annotator.css" />
<link rel="stylesheet" href="./annotator.readmill.css" />
<script src="./jquery.js"></script>
<script src="./annotator.js"></script>
<script src="./annotator.readmill.js"></script>
```

Then set up the annotator as usual calling `"addPlugin"` to setup the Readmill
plugin.

```javascript
var $book = jQuery('#book').annotator()
$book.annotator("addPlugin", "Readmill", {
  book: {
    id: "23" /* Readmill book id */
  },
  clientId: "12345678",
  callbackUri:  "http://example.com/callback.html"
});
```

[#ann-install]: https://github.com/okfn/annotator/wiki/Getting-Started
[#download]: https://github.com/aron/annotator.readmill.js/downloads

Options
-------

- `book`: An object of book metadata. This _must_ contain either an `"id"`
  property _OR_ both "title" and "author" properties. This will be used to
  look up the book on Readmill. If "title" and "author" properties are provided
  but no book is found the plugin will create the book on Readmill for you.
- `clientId`: The client id string provided by Readmill.
- `callbackUrl`: The full url of the callback.html file.
- `accessToken`: If you decide to manually handle the authentication with
  Readmill you can provide the access token when the plugin is initialized.
- `apiEndpoint`: Useful for development you can override the api endpoint
  for the Readmill API. Defaults to https://api.readmill.com
- `authEndpoint`: Useful for development you can override the auth endpoint
  for Readmill. Defaults to https://readmill.com/oauth/authenticate. If you're
  using the proxy then you'll need to set this to the proxy's url.

Development
-----------

If you're interested in developing the plugin. You can install the developer
dependancies by running the following command in the base directory:

    $ npm install .

Development requires _node_ and _npm_ binaries to be intalled on your system.
It was developed with `node --version 0.6.6` and `npm --version 1.1.0 -beta-4`.
Details on installation can be found on the [node website][#node].

To get started copy the _example.html_ file to _index.html_

    $ cp example.html index.html

Edit the intilialisation options at the bottom of the file and visit
http://localhost:8000 in your browser. You'll need to provide your own
Readmill client id.

There is a _Makefile_ containing useful commands included.

    $ make serve # serves the directory at http://localhost:8000 (requires python)
    $ make watch # compiles .coffee files into lib/*.js when they change
    $ make build # creates a production lib/annotator.readmill.js file
    $ make proxy # runs the proxy server locally at http://localhost:8080
    $ make pkg   # creates a zip file of production files

[#node]: http://nodejs.org/

### Repositories

The `development` branch should always contain the latest version of the plugin
but it is not guaranteed to be in working order. The `master` branch should
always have the latest stable code and each release can be found under an
appropriately versioned tag.

### Testing

Unit tests are located in the test/ directory and can be run by visiting
http://localhost:8080/test/index.html in your browser. Alternatively you can
[view the current suite][#suite] online on the project page.

[#suite]: http://aron.github.com/annotator.readmill.js/test/index.html

### Frameworks

The plugin uses the following libraries for development:

 - [Mocha][#mocha]: As a BDD unit testing framework.
 - [Sinon][#sinon]: Provides spies, stubs and mocks for methods and functions.
 - [Chai][#chai]:   Provides all common assertions.

[#mocha]: http://visionmedia.github.com/mocha/
[#sinon]: http://chaijs.com/
[#chai]:  http://sinonjs.org/docs/

License
-------

Released under the [MIT license][#license]

[#license]: https://raw.github.com/aron/annotator.readmill.js/master/LICENSE.md
