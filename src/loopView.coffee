class LoopView extends Backbone.View
  constructor: (options = {}) ->
    attrs = _.extend {}, @defaults, options
    if !attrs.collection? then throw new Error('No collection given')

    @preProcess()
    super(attrs)
    @collection = @options.collection

    @gather()
    @attach()

  preProcess: ->
    # sets up click/tap handlers
    addClicks = do =>
      @clickEvent = if window.mobile is true then "tap" else "click"

      @clickEvents =
        '.loop': 'view'

      for selector,method of @clickEvents
        @events["#{@clickEvent} #{selector}"] = method

  gather: ->
    @element = this.$el
    @els =
      new: $('#create')
    @templates =
      loops: Hogan.compile($("##{@options.templateId}").html())
      new:   Hogan.compile($("##{@options.newLoopTemplateId}").html())

  attach: ->
    _.bindAll this, 'edit', 'view', 'delete'

    # done with creating a loop
    @element.on 'blur', 'input.new', (e) =>
      return if @deleting is true
      @save.call(this, e.target)

    # the plus button
    @els.new.on 'click', => @collection.add([new Loop({})])

    @collection.on 'add', (model) => @new(model)
    @collection.on 'reset', => @render()
    @collection.on 'remove', (model) => @delete(model)

  el: '#loops'

  events:
    'click label': 'edit'

  defaults:
    templateId: 'loop-template'
    newLoopTemplateId: 'loop-new-template'

  new: (model, replace) ->
    data = _.extend {}, @helpers, model.toJSON()
    if replace then replace.outerHTML = @templates.new.render(data)
    else @element.prepend(@templates.new.render(data))
    @$('.new').focus()

  save: (el, model) ->
    $parent = $(el).parent()
    if !model? then model = @collection.get($parent.attr('id'))

    if el.value is '' and model.get('label') is undefined
      return @delete(model)
    else if el.value is ''
      value = model.get('label')
    else value = el.value

    model.set('label', value)
    @collection.sync 'update', model
    @render()

  view: (e) ->
    newLoop = @element.find('.new-loop')
    @deleting = true
    @delete(@collection.get(newLoop.attr('id'))) if newLoop.length > 0
    @deleting = false

    el = $(e.target)
    return if !el.is('li')
    prev = e.target.previousElementSibling
    next = e.target.nextElementSibling

    if el.hasClass('active')
      $(document.body).removeClass('viewing')
      el.siblings().css '-webkit-transform', 'translate3d(0,0,0)'
      el.removeClass('active').css '-webkit-transform',
        'translate3d(0,-' + el.offset().top + 'px,0)'
    else
      $(document.body).addClass('viewing')
      while prev? # move previous siblings over the top by index
        $prev = $(prev)
        top = $prev.offset().top + $prev.height()
        $prev.css '-webkit-transform', 'translate3d(0,-' + top + 'px,0)'
        prev = prev.previousElementSibling
      while next? # move siblings past the bottom
        $(next).css '-webkit-transform', "translate3d(0,#{window.innerHeight}px,0)"
        next = next.nextElementSibling

      el.addClass('active').css '-webkit-transform',
      'translate3d(0,-' + el.offset().top + 'px,0)'

  edit: (e) ->
    el = $(e.target).parent()
    return if el.hasClass('active')
    model = @collection.get(el.attr('id'))
    @new(model, el[0])

  delete: (model) ->
    el = $("##{model.id}")
    return if el.hasClass('active')
    el.remove()

  render: (template = @templates.loops, data) ->
    data = data or _.sortBy @collection.toJSON(), (i) ->
      -1 * @get(i.id).cid.slice(1) # neweset first
    , @collection

    templateData = _.extend {}, @helpers, loops: data
    html = template.render(templateData)
    @element.html(html)
    @postRender()
    return this

  postRender: ->
    @els.loops = @element.find('.loop')

  defineHelpers: ->
    thiz = this

    placeholder: -> @label or 'Loop Name'
