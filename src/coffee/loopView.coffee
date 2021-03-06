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
    @els =
      delete:      $('#delete')
      menu:        $('#loop-menu')
      buttons:     $('#loop-buttons')
      amountSpace: $('#amount-space')

    @expandedConfig =
      'day':   ['today', 'hours', 'days']
      'week':  ['thisWeek', 'weeks']
      'month': ['months']

  attach: ->
    thiz = this
    _.bindAll this, 'edit', 'mod'

    @clickEvent = if window.mobile is true then "tap" else "click"

    @buttonEvents =
      # button selector, method to call, args to pass
      '#subtract': method: "mod",  args: ["amount", -1]
      '#add':      method: "mod",  args: ["amount", 1]

    # for each selector inside of @element, call the object's method property
    # with the args value on either "tap" or "click"
    for selector, run of @buttonEvents
      @els.buttons.on @clickEvent, selector,
        # splat the args as args[0], args[1], ..., args[n] dyanmic yo
        _.bind(@[run.method], this, run.args...)

    # edit the amount of this loop
    @els.amountSpace.on @clickEvent, _.bind(@edit, this)

    # call viewChange when clicking one of the view buttons
    @element.on @clickEvent, '.view', _.bind(@viewChange, this)

    # call currentChange when clicking one of the current amounts
    @element.on @clickEvent, '.current', (e) ->
      index = thiz.els.currents.indexOf(this)
      range = _.keys(thiz.expandedConfig)[index]
      thiz.model.set # update the view on the modelll
        range:  range
        period: thiz.expandedConfig[range][0] # current
      thiz.render()

    # pass '' as the alternative second-menu name since a mouse event gets passed
    @els.delete.on @clickEvent, _.bind(@menu, this, 'delete', '')

    # remove a menu when not tapping a menu
    $(document).on @clickEvent, "body.menu", (e) => # TODO extract me
      el = $(e.target)
      id = el.attr('id')
      $body = $(document.body)

      # if currently viewing a loop, then hide the menu
      if !$body.hasClass('viewing') then $body.removeClass(@menuClass)
      else if $body.hasClass('mod') then '' # dont do anything
      # else if not clicking one of the menu buttons
      else if el.parent().attr('id') isnt 'menu-buttons' and !el.hasClass('button')
        $body.removeClass(@menuClass)

      return if el.is '.loop-item' # if the element was a loop list item
      # HTML will be Delete or Save, so just call the html text // #lame
      operation = $body.attr('class').match(/menu-(\w+)/)[1]
      @helpers[operation]["on" + id]?()

  amountTemplate: ->
    amount = @model.get('amount')
    "<input id='amount-template' type='tel' placeholder='#{amount}' />"

  edit: (prop) ->
    return if $('amount-template').length isnt 0
    template = @amountTemplate()
    @els.amount.html(template)
    input = @els.amount.find('input')

    blurSave = =>
      val    = input.attr('value')
      amount = @model.get('amount')
      # some backwards shit
      val    = if val is '' then amount else +val

      # if its a digit then save it
      input.off 'blur', blurSave
      if /^\d+$/.test(val) and val isnt amount
        @model.set('amount', val)
        @els.amount.html(val)
      else @els.amount.html(amount)

      @mod('amount', 0) # update the menu

    input.on 'blur', -> blurSave()
    input.focus() # balls ass

  mod: (prop, amount) ->
    val = (@model.get(prop) or 0) + amount
    val = 0 if val <= 0 # CLEAN
    @els[prop].html(val)
    # prop is always 'amount'..
    @model.set(prop, val) # fires the 'change' event

    if val <= 0 # don't allow negative numbers
      $(document.body).removeClass(@menuClass or '')
    else
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
    $parent = $("##{@model.get('id')}") # loop id

    properRemove = (e) ->
      $this = $(this)
      if $this.is('li') then $this.remove() else $this.html('')
      $this.off e.type, properRemove

    els = $parent.add(@element)
    els.on
      'webkitTransitionEnd': properRemove
      'transitionEnd':       properRemove

    loopsView.view(target: $parent)
    els.addClass('delete')

    @collection.remove(@model.get('id'))

  save: ->
    point = val: @model.get('amount'), time: +new Date()
    data = @model.get('data')
    data[@currentPoint or point.time] = point.val
    @model.set('data', data) # updates the data points
    @collection.save() #FIXME
    @cancel() # close the menu
    @render() # re-render the view

  cancel: ->
    @model.set('amount', 0)
    @els.amount.html(0)
    $(document.body).removeClass(@menuClass)
    @menuClass = ''

  viewChange: (e) ->
    $el  = $(e.target)
    view = $el.data('range')
    @element.find('.view.active').removeClass('active')
    $el.addClass('active')

    # tell the Graph to render a new data type yo
    @trigger('viewChange', @model.set('period', view))

  getModelData: -> @latestModelData = @model.collect() # lol

  # finds the most recent 'day'(today), 'week', 'month'
  getCurrentData: ->
    data = @latestModelData or @getModelData()
    interesting = [data.weeks, data.months]
    # current 'day', 'week', 'month'
    current = _.map interesting, (x) -> _.last(x)

    todaysData = # TODO make schemapping and assign
      sum: _.reduce(data.today, ((a,b) -> a + b.sum), 0)
      headline: 'Today'
      by: 'today'

    data.thisWeek = @model.migrate(
      { thisWeek: (p) -> moment(+p.time).day() }, # mapping
      { thisWeek: { by: 'This Week',  points: [], sum: 0 } }, # schema
      { thisWeek: _.range(7) }, # index of day of week for labels
      _.last(data.weeks).points # the data to migrate
    ).thisWeek # grab the property off the data object returned

    # push todaysData to the front for the template
    return _.flatten [todaysData, current]

  render: (template = @templates.loop, @model = @model) ->
    if !@helpers? then @helpers = @defineHelpers()
    if @model.get('amount') isnt 0 then @menu('save', 'mod')

    @latestTemplateData = _.extend
      modelData:   @getModelData()
      currentData: @getCurrentData()
    , @helpers, @model.attributes

    @element.html(Mustache.render(template, @latestTemplateData))
    @postRender()
    # update the session and graph
    @trigger 'render', this,
      model: @model

  postRender: ->
    _.extend @els, # re-gather elements rendered from the template
      amount: @element.find('#amount')
      currents: @element.find('.current')

    loopsView.els.container.css
      height:       window.ogHeight
      'max-height': window.ogHeight

  # tell the loopsView to render this view with this model
  restore: (@model, @expandedDetail) -> @trigger('restore', @model)

  defineHelpers: ->
    thiz = this

    # loop-button methods dynamically called by their innerhtml
    delete:
      oncancel: => $(document.body).removeClass(@menuClass)
      cancel: "Cancel"
      onsave: _.bind(@delete, this)
      save:   "Delete"
    save:
      oncancel: _.bind(@cancel, this)
      cancel: "Cancel"
      onsave:  _.bind(@save, this)
      save:   "Save"

    # return the totaled array of current data
    # [data.today, data.this week, data.this month]
    currents: ->
      for collection in @currentData # set headlines
        collection.headline or= switch collection.by
          when 'by week'  then 'This Week'
          when 'by month' then 'This Month'
      return @currentData

    # if the current 'current' bin is the viewing
    active: ->
      range  = thiz.model.get('range')
      period = thiz.model.get('period')

      val =
        if /[\w+\s\w+]$/.test(''+this) then period is @concat()
        else if range is 'day' and @by is 'today' then true
        # remove the 'by' from 'by week'
        else range is @by.split(' ')[1]

      if val is true then 'active' else ''

    amount: => @model.attributes.amount or 0

    views: =>
      views = @expandedConfig[@model.get('range')]
      if views.length is 1 then [] else views

    rangeLabel: ->
      # get the first object's 'by' label from the model data '' + this will be
      # 'month' or 'thisWeek' from iterating through the view configs
      thiz.latestModelData[''+this][0].by
