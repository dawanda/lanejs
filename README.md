# lanejs

lanejs is a Ruby on Rails like MVC framework for javascript written in coffeescript. You can use it for SEO friendly pages.

## Getting Started

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