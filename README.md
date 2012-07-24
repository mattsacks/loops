## Loops

A web app for counting things over time. It makes no calls to outside websites
and all data lives in `localStorage`.

Designed for use from the home screen on an iPhone but also works in desktop
browsers.

## Why

I wanted a general purpose tracker for qualitative data over time to create
small-friction feedback loops. Everything else was either overpriced, too
complex, or had no visualization mechanism.

## Code

All source is written in [CoffeeScript](http://coffeescript.org),
[SASS](http://sass-lang.com), and [HAML](http://haml.info).  

There are no images used (besides the app icon).  

All fonts are from [Google Web Fonts](http://www.google.com/webfonts/).

#### 3rd Party

* [d3.js](http://d3js.org/)
* [Zepto.js](http://zeptojs.com/)
* [Backbone.js](http://backbonejs.org/)
* [Underscore.js](http://underscorejs.org/)
* [Backbone.localStorage](https://github.com/jeromegn/Backbone.localStorage)(slightly modified)
* [Moment.js](http://momentjs.com/)
* [Mustache.js](https://github.com/janl/mustache.js/)
* [Grunt.js](http://gruntjs.com/)

## Developing

All development takes place on the `master` branch. I use
[LiveReload](http://livereload.com/) and highly recommend it. It should pick up
the script tag in `index.haml` and live compile the source as you change it.

To fire up a server, on OS X you can execute the common `python -m
SimpleHTTPServer` in the terminal located at this directory. Find your IP
address with `ifconfig` and then just go to `192.168.1.xxx:8000` or whatever the
IP:port is on your iOS device (or browser).

## FAQ

* _What about sync?_  
  Nope

* _How about export/import?_  
  Will do something like anonymous posting to private gists

* _Better iPad support?_  
  Yeah, later

* _What about Android support?_  
  No

* _How do I custom set the loops data?_  
  Type out `JSON.parse(localStorage.getItem('loops'))` in the console to see how
  the data should be structured. Set it with `localStorage.setItem`

* _Why is the box glowing?_  
  Because I thought it was cool and took [no code](https://github.com/mattsa/loops/blob/master/src/sass/_animations.sass)

* _I don't like the music_  
  That sucks

* _I want to add songs to the music list_  
  Totally. Open a pull request with a link
