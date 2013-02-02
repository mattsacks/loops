class LoopsView extends Backbone.View
  constructor: (options = {}) ->
    attrs = _.extend {}, @defaults, options
    if !attrs.collection? then throw new Error('No collection given')

    @preProcess()
    super(attrs)

    # TODO throw an error, these are required to be passed in
    {@collection, @subView} = @options

    @gather() # gatehr elements
    @attach() # attach bindings to them
    @helpers = @defineHelpers() # cache template helpers for rendering

  # mostly to add proper 'click' or 'tap' events to the @events object
  preProcess: ->
    # sets up click/tap handlers
    addClicks = do =>
      @clickEvent = if window.mobile is true then "tap" else "click"

      @clickEvents =
        '.loop-item': 'view'
        'label':      'edit'

      for selector,method of @clickEvents
        @events["#{@clickEvent} #{selector}"] = method

      @events['keydown .new-loop'] = (e) ->
        if e.keyCode is 13 # return / enter key
          e.preventDefault()
          $(e.target).blur() # cheap save
        else if e.keyCode is 27 # cancel on 'esc' FIXME
          e.preventDefault()
          $(e.target).attr('value', '').blur()

  # cache templates, elements, jQuery objects, etc
  gather: ->
    @element = this.$el
    @els =
      new: $('#create')
      portability: $('#data-buttons')
      additional: $('#additional')
      container: $('.container')
    @templates =
      loops: $("##{@options.templateId}").html()
      new:   $("##{@options.newLoopTemplateId}").html()

  # bind methods to events on the gathered elements
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

    @collection.on 'add', (model) => @new(model) # FIXME edit should handle replacing the element
    @collection.on 'reset', => @render()
    @collection.on 'remove', (model) => @delete(model)

    @subView.on 'restore', _.bind(@restore, this)

  el: '#loops' # the jQuery reference to refer to in @element

  events: {} # gets modified in @preProcess before calling super

  # merged into the passed in attributes if not overridden in the constructor
  defaults:
    templateId: 'loop-template'
    newLoopTemplateId: 'loop-new-template'

  # model:   a model to grab attributes from if editing it
  # replace: an element to replace with the new Loop template otherwise, 
  #          just add it to the top of the view
  new: (model, replace) ->
    data = _.extend {}, @helpers, model.toJSON()
    html = Mustache.render(@templates.new, data)

    # replace in the case of editing an existing transaction
    if replace then replace.outerHTML = html else @element.prepend(html)
    @$('.new').focus() # focus the name of the new loop

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
    @collection.sync 'update', model.attributes
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

    # scroll to top
    if scrollY isnt 0
      if window.mobile is true then window.scrollTo(0,0)
      else $.scroll(0)

    if !$(document.body).hasClass('viewing') # the loops view
      @slideList(e.target)
      @subView.render(null, @collection.get(e.target.id))
      setTimeout =>
        $(document.body).attr('class', 'show viewing ' + @subView.menuClass)
      , 1
    else #closing a view
      @setContainer()
      @slideList(e.target)
      @subView.menuClass = ''
      $(document.body).attr('class', 'show')
      @trigger('render', this)

  # open or close the loop list
  # returns: true if ending as opened (viewing a loop)
  #          false if ending as closed (now viewing the loop list)
  slideList: (element) ->
    $el = $(element)
    prev = element.previousElementSibling
    next = element.nextElementSibling
    transform = browser.flag + "transform" # include prefix

    offset   = @element.offset().top
    elOffset = $el.offset().top - offset

    if $el.hasClass('active') # close viewing a loop
      @element.css(transform, 'translate3d(0,0,0)').css('height', '')

      $el.removeClass('active').css transform, 'translate3d(0,-' + elOffset + 'px,0)'
      $el.siblings().css transform, 'translate3d(0,0,0)'
      #@els.portability.css transform, 'translate3d(0,0,0)'
      @els.additional.removeClass('slide')

      return false # the view is closed
    else # open a loop!
      padding = if window.mobile is true then 0 else 30
      @element.css(transform, 'translate3d(0,-'+ offset+'px,0)')
              .css('height', window.ogHeight - offset - padding)

      $el.addClass('active').css transform,
        'translate3d(0,-' + elOffset + 'px,0)'

      while prev? # move previous siblings over the top by index
        $prev = $(prev)
        top = $prev.offset().top + $prev.height()
        $prev.css transform, 'translate3d(0,-' + top + 'px,0)'
        prev = prev.previousElementSibling

      while next? # move siblings past the bottom
        $(next).addClass('next')
               .css transform, "translate3d(0,#{window.ogHeight}px,0)"
        next = next.nextElementSibling

      @els.additional.addClass('slide')
      #@els.portability.css transform, "translate3d(0,#{window.ogHeight}px,0)"
      return true # the view is now open

  # called on tapping the name of a loop in any view
  # e is an event object which should represent the <input> element inside a .loop-item
  edit: (e) ->
    el = $(e.target).parent()
    # if tapping on the name when viewing a loop, probably intend to close it
    # so call the view method as if tapping the list item
    return @view(target: el[0]) if el.hasClass('active')

    # call the new method so it can just do an outerHTML on the loop-item with
    # the same template and data and stuff
    model = @collection.get(el.attr('id'))
    @new(model, el[0])

  # removes an empty new Loop item FIXME this could be tuned
  delete: (model) ->
    id = model.get('id')
    $("##{id}").remove()

  # render the loop-list
  render: (template = @templates.loops, data) ->
    data = data or _.sortBy @collection.toJSON(), (i) ->
      -1 * @get(i.id).cid.slice(1) # newest first
    , @collection

    templateData = _.extend {}, @helpers, loops: data
    @latestTemplateData = templateData
    html = Mustache.render(template, templateData)
    @element.html(html)
    @postRender()
    return this

  postRender: ->
    # stash the rendered loop elements
    @els.loops = @element.find('.loop-item')

    # if there's now more than one loop, show the export option
    if @collection.models.length > 0 then @els.portability.addClass('show')
    else @els.portability.removeClass('show')
    @setContainer()

  # set a min height on the container to show all the loops
  setContainer: ->
    height = @els.loops.length * @els.loops.height()
    if window.mobile is true and height >= 370
      @els.container.css
        height:       height + 75
        'max-height': height + 75

  # called on loading the page if the session.view value is 'loopView'
  # when called from LoopView with a model, view that Loop
  restore: (model) ->
    @render()
    if model then @view(target: $("##{model.id}")[0])

  # helpers used in the mustache templates in @templates
  defineHelpers: ->
    thiz = this

    placeholder: -> @label or 'Loop Name'
