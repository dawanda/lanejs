module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('bower.json')

    bower:
      options:
        targetDir: "./vendor"
      install: { }

    curl:
      'vendor/cartograph.js':     'https://raw.githubusercontent.com/dawanda/cartograph/master/lib/cartograph.js'
      'vendor/eventspitter.js':   'https://raw.githubusercontent.com/lucaong/eventspitter/master/lib/eventspitter.js'
      'vendor/loud-accessors.js': 'https://raw.githubusercontent.com/lucaong/loud-accessors/master/lib/loud-accessors.js'
      'vendor/submachine.js':     'https://raw.githubusercontent.com/lucaong/submachine/master/lib/submachine.js'

    meta:
      banner:
        '// lanejs\n' +
        '// version: <%= pkg.version %>\n' +
        '// author: <%= pkg.author %>\n' +
        '// license: <%= pkg.licenses[0].type %>\n'

    coffee:
      all:
        options:
          join: true
        files:
          'dist/lib.js': [
            'src/namespace.js.coffee'
            'src/module.js.coffee'
            'src/timeout.js.coffee'
            'src/model.js.coffee'
            'src/persistable.js.coffee'
            'src/crud.js.coffee'
            'src/controller.js.coffee'
            'src/request.js.coffee'
            'src/cookie.js.coffee'
            'src/navigator.js.coffee'
            'src/router.js.coffee'
            'src/stateful_widget.js.coffee'
            'src/i18n.js.coffee'
            'src/validators.js.coffee'
            'src/url_builder.js.coffee'
          ]

    concat:
      all:
        files:
          'dist/lanejs.js': [
            'vendor/**/*.js'
            'dist/lib.js'
          ]

    uglify:
      all:
        options:
          report: 'gzip'
        files:
          'dist/lanejs.min.js': 'dist/lanejs.js'

    karma:
      options:
        basePath: ''
        configFile: 'karma.conf.js'
        loadFiles: [ 'dist/lanejs.js', 'spec/**/*.coffee' ]
      continuous: { }

    clean: ["dist/lib.js"]

    release:
      options:
        file: 'bower.json'

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-jasmine'
  grunt.loadNpmTasks 'grunt-bower-task'
  grunt.loadNpmTasks 'grunt-karma'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-curl'
  grunt.loadNpmTasks 'grunt-release'

  # Run with grunt release, grunt release:minor

  grunt.registerTask 'build',   ['bower:install', 'curl', 'coffee', 'concat', 'clean', 'uglify', 'karma:continuous']