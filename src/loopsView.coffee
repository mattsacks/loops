class LoopsView extends Backbone.View
  constructor: (options = {}) ->
    attrs = _.extend {}, @defaults, options
    if !attrs.collection? then throw new Error('No collection given')

    @preProcess()
    super(attrs)
    @collection = @options.collection

    @gather()
    @attach()
    @helpers = @defineHelpers()

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
      portability: $('#data-buttons')
      container: $('.container')
    @templates =
      loops: Hogan.compile($("##{@options.templateId}").html())
      new:   Hogan.compile($("##{@options.newLoopTemplateId}").html())

  attach: ->
    _.bindAll this, 'edit', 'view', 'delete'

    # done with creating a loop
    @element.on 'blur', 'input.new', (e) => @save.call(this, e.target)

    # the plus button
    @els.new.on @clickEvent, =>
      # if editing something
      newLoop = @$('.new-loop input')
      newLoop.blur() if newLoop.length > 0
      @collection.add([new Loop({})])

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
    @$('.new').focus() # trigger's view on new element

  # occurs on 'blur' for a '.new-loop'
  save: (el, model) ->
    $parent = $(el).parent()
    if !model? then model = @collection.get($parent.attr('id'))

    if el.value is '' and model.get('label') is undefined
      return @collection.remove(model) # fires @delete
    else if el.value is ''
      value = model.get('label')
    else value = el.value

    model.set('label', value)
    @collection.sync 'update', model
    @render()

  # tapping a .loop item to view it
  view: (e) ->
    el = $(e.target)
    return if !el.is('li')

    $newLoop = @element.find('.new-loop')
    if $newLoop[0]?
      newLoop = @collection.get($newLoop.attr('id'))
      @save($newLoop.find('input')[0], newLoop)
      # update el references, saving re-renders the template
      el = $("##{e.target.id}")
      e.target = el[0]

    prev = e.target.previousElementSibling
    next = e.target.nextElementSibling

    if el.hasClass('active')
      $(document.body).removeClass('viewing')
      el.siblings().css '-webkit-transform', 'translate3d(0,0,0)'
      @els.portability.css '-webkit-transform', 'translate3d(0,0,0)'
      el.removeClass('active').css '-webkit-transform',
        'translate3d(0,-' + el.offset().top + 'px,0)'
    else
      el.addClass('active').css '-webkit-transform',
        'translate3d(0,-' + el.offset().top + 'px,0)'

      while prev? # move previous siblings over the top by index
        $prev = $(prev)
        top = $prev.offset().top + $prev.height()
        $prev.css '-webkit-transform', 'translate3d(0,-' + top + 'px,0)'
        prev = prev.previousElementSibling
      while next? # move siblings past the bottom
        $(next).css '-webkit-transform', "translate3d(0,#{window.innerHeight}px,0)"
        next = next.nextElementSibling

      @els.portability.css '-webkit-transform', "translate3d(0,#{window.innerHeight}px,0)"
      $(document.body).addClass('viewing')

  # tapping the input
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
    @latestTemplateData = templateData
    html = template.render(templateData)
    @element.html(html)
    @postRender()
    return this

  postRender: ->
    @els.loops = @element.find('.loop')

    if @collection.models.length > 0 then @els.portability.addClass('show')
    else @els.portability.removeClass('show')

    # update height of container
    height = @els.loops.length * @els.loops.height()
    if window.mobile is true and height >= 460
      @els.container.css
        height:       height + 130 # buffer for bottom buttons
        'max-height': height + 130

  defineHelpers: ->
    thiz = this

    placeholder: -> @label or 'Loop Name'
