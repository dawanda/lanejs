![LaneJS](http://i.imgur.com/ARmKHa4.png)
# lanejs
[![Build Status](https://travis-ci.org/dawanda/lanejs.svg?branch=master)](https://travis-ci.org/dawanda/lanejs)

lanejs is a Ruby on Rails like MVC framework for javascript written in coffeescript. You can use it for SEO friendly pages.

## Getting Started

### Create a Model
```coffee
namespace "DaWanda.Models.Message", ->

  class Message extends Lib.Model
    @attrAccessible "subject", "text", "from", "to", "image_field", "hidden", "subject_type", "subject_id"
    @validates "from", presence: true
    @validates "subject", presence: true
    @validates "text", presence: true
    @validates "to", presence: true
    @validates "image_field", format:
      with: /.*\.(jpg|jpeg|png|gif)$/i
      message: I18n.t("errors.messages.file_format_invalid")

    # Use Crud to load and save data from JSON
    @extend Lib.Crud
    @resource "message"
    @endpoint "/core/messages"
```

### Create a Controller
```coffee
namespace "DaWanda.Controllers.MessagesController", ->

  class MessagesController extends Lib.Controller

    @beforeFilter '_doSomething'

    index: ->
      @messages = [new DaWanda.Models.Message(from: "me", to: "you", subject: "i like you", text: "really <3")]

    new: ->
      @message = new DaWanda.Models.Message()

    edit: ->
      DaWanda.Models.Message.find(id: @params["id"]).done ( message ) =>
        @message = message

    _doSomething: ->
      # TODO

```

### Create Routes File
```coffee
Lib.Router.draw ->

  @match "/foo/:id", "foo#show"

  # Map a resource (will look for UsersController
  # and map index, show, new and update actions)
  @resources "users", ->
    # You can add additional members/collection actions
    @member "profile"
    @collection "top_influencers"

  # You can nest resources too
  @resources "shops", ->
    @resources "products"

  # Map a singular resource (will look for CartController
  # and map show, new and edit actions)
  @resource "cart"
```

### Create a Stateful Widget
### Integrate with rivets.js
### Integrate with eco
### Use with [rails-assets.org](https://rails-assets.org/)
Change your gemfile so it looks like:
```
source 'https://rails-assets.org'

gem 'rails-assets-lanejs'
```

## Building and Testing

### Install Dependencies
For building and testing it is neccessary to install npm and run `npm install --dev`.

It is recommended to install the [grunt-cli](https://github.com/gruntjs/grunt-cli) and [karma-cli](https://github.com/karma-runner/karma-cli) tool:
```
npm install -g grunt-cli
npm install -g karma-cli
```

### Build Project

### Run Tests
Tests are running with [karma.js](http://karma-runner.github.io/) and are built with [jasmine](http://jasmine.github.io/).
```
karma start
```

## Contributing

#### Bug Reporting

1. Ensure the bug can be reproduced on the latest master.
2. Open an issue on GitHub and include an isolated [JSFiddle](http://jsfiddle.net/) demonstration of the bug. The more information you provide, the easier it will be to validate and fix.

#### Pull Requests

1. Fork the repository and create a topic branch.
2. Be sure to associate commits to their corresponding issue using `[#1]` or `[Closes #1]` if the commit resolves the issue.
3. Make sure not to commit any changes under `dist/` as they will surely cause merge conflicts later. Files under `dist/` are only committed when a new build is released.
4. Include tests for your changes and make them pass.
5. Push to your fork and submit a pull-request with an explanation and reference to the issue number(s).