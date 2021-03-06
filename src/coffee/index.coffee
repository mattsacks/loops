# add functionality to moment.js
do (moment) ->
  # get the week of the year
  moment.fn.week = (week) -> +@format("w")
(moment)

# i can't believe people put up with this bullshit underscore
do (_) ->
  _.mixin
    # copies everything into a new object
    copy: (properties) ->
      obj = {}
      for key, value of properties
        obj[key] = if Array.isArray(value) then value.slice() else value
      return obj
(_)

Math.getRandomInt = (min, max) ->
  Math.floor(Math.random() * (max - min + 1)) + min

class Browser
  constructor: ->
    @lUA = navigator.userAgent.toLowerCase()
    @platform = navigator.platform.toLowerCase()
    @UA = @lUA.match(/(opera|ie|firefox|chrome|version)[\s\/:]([\w\d\.]+)?.*?(safari|version[\s\/:]([\w\d\.]+)|$)/) || [null, 'unknown', 0]
    @mode = @UA[1] == 'ie' && document.documentMode

    @name = if @UA[1] == 'version' then @UA[3] else @UA[1]
    @version = this.mode or parseFloat(if (@UA[1] == 'opera' and @UA[4]) then @UA[4] else @UA[2])

    @Platform =
      name: if @lUA.match(/ip(?:ad|od|hone)/) then 'ios' else (@lUA.match(/(?:webos|android)/) or @platform.match(/mac|win|linux/) || ['other'])[0]

    @Features =
      xpath: !!(document.evaluate)
      air:   !!(window.runtime)
      query: !!(document.querySelector)
      json:  !!(window.JSON)

    @flag =
      if @name is 'unknown'
        switch(@Platform.name)
          when 'ios' then '-webkit-'
          when 'android' then '-webkit-'
          when 'webos'   then '-webkit-'
      else
        switch(@name) # css flag
          when 'chrome' then '-webkit-'
          when 'safari' then '-webkit-'
          when 'firefox' then '-moz-'
          when 'ie' then '-ms-'
          when 'opera' then '-o-'
          else ''

$ -> # document.ready
  # window.session = new Session(data.session)
  window.browser  = new Browser()
  # cache original height before render
  window.ogHeight = window.innerHeight
  window.platform = browser.Platform.name
  window.mobile =
    if platform is 'ios' or platform is 'android' then true
    else false

  window.loops      = new Loops()
  window.loopView   = new LoopView(collection: loops)
  window.graph      = new Graph(view: loopView)
  window.loopsView  = new LoopsView
    collection: loops
    subView:    loopView

  window.session  = new Session('loopsView', 'loopView')

  # new visitor!
  if window.navigator.standalone is false
    $(document.body).addClass('to-install')

  $(document.body).addClass('show')

  #window.addEventListener 'load', ->
  #  setTimeout ->
  #    window.scrollTo(0,0)
  #  , 10
