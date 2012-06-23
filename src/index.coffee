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
