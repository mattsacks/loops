$ -> # document.ready
  # window.session = new Session(data.session)
  window.loops    = new Loops()
  window.loopView = new LoopView(loops).render()

  $(document.body).addClass('show')

  #window.addEventListener 'load', ->
  #  setTimeout ->
  #    window.scrollTo(0,0)
  #  , 10
