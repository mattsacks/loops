# add functionality to moment.js
do (moment) ->

  # get or set the week of the year
  # this may or may not be accurate..
  moment.fn.week = (week) ->
    # start of the year from day of the week mod
    mod = moment().date(1).month(0).day() % 7

    # if no amount to set passed, then return the week set
    return Math.floor((+@format("DDD") + mod) / 7) if !week?

    # else set the week, but keep it on the same day of the week
    doy = (@day() - mod) + ((week-1) * 7)
    return @date(1).month(0).add('days', doy)

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


$ -> # document.ready
  # window.session = new Session(data.session)
  window.browser  = new Browser()
  window.platform = browser.Platform.name
  window.mobile =
    if platform is 'ios' or platform is 'android' then true
    else false

  window.loops     = new Loops()
  window.loopView  = new LoopView(collection: loops)
  window.loopsView = new LoopsView
    collection: loops
    subView:    loopView

  window.session  = new Session('loopsView', 'loopView')

  $(document.body).addClass('show')

  #window.addEventListener 'load', ->
  #  setTimeout ->
  #    window.scrollTo(0,0)
  #  , 10
