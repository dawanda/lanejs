// Karma configuration
// Generated on Tue Apr 29 2014 17:16:48 GMT+0200 (CEST)

module.exports = function(config) {
  config.set({

    // base path that will be used to resolve all patterns (eg. files, exclude)
    basePath: '',


    // frameworks to use
    // available frameworks: https://npmjs.org/browse/keyword/karma-adapter
    frameworks: ['jasmine', 'sinon-chai'],

    // list of files / patterns to load in the browser
    files: [
      'vendor/**/*.js',
      'src/namespace.js.coffee',
      'src/module.js.coffee',
      'src/timeout.js.coffee',
      'src/model.js.coffee',
      'src/persistable.js.coffee',
      'src/crud.js.coffee',
      'src/controller.js.coffee',
      'src/request.js.coffee',
      'src/cookie.js.coffee',
      'src/navigator.js.coffee',
      'src/router.js.coffee',
      'src/stateful_widget.js.coffee',
      'src/i18n.js.coffee',
      'src/validators.js.coffee',
      'src/url_builder.js.coffee',
      'spec/**/*.coffee'
    ],


    // list of files to exclude
    exclude: [
      
    ],


    // preprocess matching files before serving them to the browser
    // available preprocessors: https://npmjs.org/browse/keyword/karma-preprocessor
    preprocessors: {
      '**/*.coffee': ['coffee']
    },


    // test results reporter to use
    // possible values: 'dots', 'progress'
    // available reporters: https://npmjs.org/browse/keyword/karma-reporter
    reporters: ['progress'],


    // web server port
    port: 9876,


    // enable / disable colors in the output (reporters and logs)
    colors: true,


    // level of logging
    // possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
    logLevel: config.LOG_INFO,


    // enable / disable watching file and executing tests whenever any file changes
    autoWatch: false,


    // start these browsers
    // available browser launchers: https://npmjs.org/browse/keyword/karma-launcher
    browsers: ['Chrome'],


    // Continuous Integration mode
    // if true, Karma captures browsers, runs the tests and exits
    singleRun: true
  });
};
