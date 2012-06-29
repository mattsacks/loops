class LoopView extends Backbone.View
  constructor: (options = {}) -> 
    modoptions = _.extend {}, @defaults, options
    super(modoptions)

    @gather()
    @attach()

  defaults:
    loopTemplate: $('#loop-detail-template').html()
    menuTemplate: $('#loop-menu-template').html()

  el: '#loop'

  events: {}

  gather: ->
    @templates =
      loop: @options.loopTemplate
      menu: @options.menuTemplate

    @element  = this.$el
    @els      =
      delete:  $('#delete')
      menu:    $('#loop-menu')
      buttons: $('#loop-buttons')

  attach: ->
    _.bindAll this, 'edit', 'mod'

    @clickEvent = if window.mobile is true then "tap" else "click"

    @buttonEvents =
      # button selector, method to call, args to pass
      '#amount':   method: "edit", args: ["amount"]
      '#subtract': method: "mod",  args: ["amount", -1]
      '#add':      method: "mod",  args: ["amount", 1]

    # for each selector inside of @element, call the object's method property
    # with the args value on either "tap" or "click"
    for selector, run of @buttonEvents
      @els.buttons.on @clickEvent, selector,
        # splat the args as args[0], args[1], ..., args[n] dyanmic yo
        _.bind(@[run.method], this, run.args...)

    # pass '' as the alternative second-menu name since a mouse event gets passed
    @els.delete.on @clickEvent, _.bind(@menu, this, 'delete', '')

    # remove a menu when not tapping a menu
    $(document).on @clickEvent, "body.menu", (e) =>
      el = $(e.target)
      id = el.attr('id')
      $body = $(document.body)
      if !$body.hasClass('viewing') then $body.removeClass(@menuClass)
      else if $body.hasClass('mod') then '' # FIXME dont do anything
      else if el.parent().attr('id') isnt 'menu-buttons' and !el.hasClass('button')
        $body.removeClass(@menuClass)

      # HTML will be Delete or Save, so just call the html text
      return if el.is '.loop-item'
      operation = $body.attr('class').match(/menu-(\w+)/)[1]
      @helpers[operation]["on" + id]?()

  edit: (prop) ->

  mod: (prop, amount) ->
    val = (@model.get(prop) or 0) + amount
    @els[prop].html(val)
    @model.set(prop, val) # fires the 'change' event
    @menu('save', 'mod')

  # opens the menu and hides the #delete button, attaches an event on the body
  # for any tap that's outside of its elements to dismiss it
  # operation: 'delete', 'save'
  menu: (operation, menu = '') ->
    @menuClass = "menu menu-#{operation} #{menu}"
    html = Mustache.render(@templates.menu, @helpers[operation])
    @els.menu.html(html)
    $(document.body).addClass(@menuClass)

  delete: ->
    $parent = $("##{@model.get('id')}")
    
    properRemove = (e) ->
      $this = $(this)
      if $this.is('li') then $this.remove() else $this.html('')
      $this.off e.type, properRemove

    els = $parent.add(@element)
    els.on
      'webkitTransitionEnd': properRemove
      'transitionEnd': properRemove

    loopsView.view(target: $parent)
    els.addClass('delete')

    @collection.remove(@model.get('id'))

  save: ->
    point = val: @model.get('amount'), time: +new Date()
    data = @model.get('data')
    data[@currentPoint or point.time] = point.val
    @model.set('data', data)
    @collection.save() #FIXME
    @cancel()
    @render()

  cancel: ->
    @model.set('amount', 0)
    @els.amount.html(0)
    $(document.body).removeClass(@menuClass)
    @menuClass = ''

  render: (template = @templates.loop, @model = @model) ->
    debugger
    if !@helpers? then @helpers = @defineHelpers()
    if @model.get('amount') isnt 0 then @menu('save', 'mod')

    @latestTemplateData = _.extend {}, @helpers, @model.attributes

    @element.html(Mustache.render(template, @latestTemplateData))
    @postRender()
    @trigger('render', this, model)

  postRender: ->
    _.extend @els, # re-gather
      amount: @element.find('#amount')

  restore: (@model) ->
    @trigger('restore', @model)

  defineHelpers: ->
    thiz = this

    # loop-buttons
    delete:
      oncancel: => $(document.body).removeClass(@menuClass)
      cancel: "Cancel"
      onsave: _.bind(@delete, this)
      save:   "Delete"
    save: # lol
      oncancel: _.bind(@cancel, this)
      cancel: "Cancel"
      onsave:  _.bind(@save, this)
      save:   "Save"

    # finds the most recent 'day'(today), 'week', 'month'
    currents: =>
      data = @model.collect()
      return if !data?
      interesting = [data.today, data.weeks, data.months]
      # current 'day', 'week', 'month'
      current = _.map interesting, (x) -> _.last(x)
      for collection in current
        collection.headline = switch collection.by
          when 'hour'  then 'Today'
          when 'week'  then 'This Week'
          when 'month' then 'This Month'
      return current

    # this is pretty dumb
    amount:   => @model.attributes.amount or 0
