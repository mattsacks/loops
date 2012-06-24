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
      loop: Hogan.compile(@options.loopTemplate)
      menu: Hogan.compile(@options.menuTemplate)

    @element  = this.$el
    @els      =
      delete: $('#delete')
      menu:   $('#loop-menu')

  attach: ->
    _.bindAll this, 'edit', 'mod'

    @clickEvent = if window.mobile is true then "tap" else "click"

    @clickEvents =
      '#amount':
        method: "edit",
        args: ["amount"]
      '#subtract': method: "mod",  args: ["amount", -1]
      '#add':      method: "mod",  args: ["amount", 1]

    # for each selector inside of @element, call the object's method property
    # with the args value on either "tap" or "click"
    for selector, run of @clickEvents
      (@element).on @clickEvent, selector,
        # splat the args as args[0], args[1], ..., args[n] dyanmic yo
        _.bind(@[run.method], this, run.args...)

    @els.delete.on 'click', _.bind(@menu, this, 'delete')

    # remove a menu when not tapping a menu
    $(document).on @clickEvent, "body.menu", (e) =>
      el = $(e.target)
      id = el.attr('id')
      $body = $(document.body)
      if el.parent().attr('id') isnt 'menu-buttons' and id isnt 'delete'
        $body.removeClass(@menuClass)

      # HTML will be Delete or Save, so just call the html text
      if id is "save" then this[el.html().toLowerCase()]()
      else if id is "cancel" then $body.removeClass(@menuClass)

  edit: (prop) ->

  mod: (prop, amount) ->
    val = (@model.get(prop) or 0) + amount
    @els[prop].html(val)
    @model.set(prop, val) # fires the 'change' event

  # opens the menu and hides the #delete button, attaches an event on the body
  # for any tap that's outside of its elements to dismiss it
  # operation: 'delete', 'save'
  menu: (operation) ->
    @menuClass = "menu menu-#{operation}"
    html = @templates.menu.render(@helpers[operation])
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

  render: (template = @templates.loop, @model) ->
    if !@helpers? then @helpers = @defineHelpers()

    @latestTemplateData = _.extend {}, @helpers, @model

    @element.html(template.render(@latestTemplateData))
    @postRender()
    @trigger('render', this, model)

  openMenu: ->

  postRender: ->
    _.extend @els, # re-gather
      amount: @element.find('#amount')

  restore: (@model) ->
    @trigger('restore', @model)

  defineHelpers: ->
    thiz = this

    amount: ->
      val = @get('amount') or 0
      if val isnt 0 then thiz.openMenu()
      return val

    delete:
      cancel: "Cancel"
      save:   "Delete"
