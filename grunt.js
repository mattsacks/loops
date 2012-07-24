module.exports = function(grunt) {
  grunt.initConfig({
    concat: {
      deps: {
        src: ['js/lib/zepto.min.js', 'js/lib/underscore-min.js', 'js/lib/backbone-min.js', 'js/lib/backbone-localstorage.js','js/lib/moment.min.js', 'js/lib/mustache.js',  'js/lib/d3.v2.min.js'],
        dest: 'deps.js'
      },
      source: {
        src: ['js/loop.js', 'js/loopView.js', 'js/graph.js', 'js/loopsView.js', 'js/session.js', 'js/index.js'],
        dest: 'src.js'
      }
    },
    min: {
      source: {
        src: 'src.js',
        dest: 'src.min.js'
      }
    }
  });
};