class LoopView extends Backbone.View
  constructor: (collection, options = {}) ->
    _.extend options, @defaults
    super(options)
    @collection = collection
    @template = Hogan.compile($("##{options.templateId}").html())

    @gather()
    @attach()

  gather: ->
    @element = this.$el
    @els =
      new: $('#create')
    @templates =
      new: $('#loop-new-template').html()

  attach: ->
    _.bindAll this, 'edit', 'view', 'delete'

    # done with creating a loop
    @element.on 'blur', 'input.new', (e) => @save.call(this, e.target)

    # the plus button
    @els.new.on 'click', => @collection.add([new Loop({})])

    @collection.on 'add', (model) => @new(model)
    @collection.on 'update', => @render()
    @collection.on 'remove', => @render()
    @collection.on 'reset', => @render()

  el: '#loops'

  events:
    'click .loop':     'view'
    'click label':     'edit'
    'swipeLeft .loop': 'delete'

  defaults:
    templateId: 'loop-template'

  new: (model, replace) ->
    template = Hogan.compile(@templates.new)
    data = _.extend {}, @helpers, model.toJSON()
    if replace then replace.outerHTML = template.render(data)
    else @element.prepend(template.render(data))
    @$('.new').focus()

  save: (el, model) ->
    if !model? then model = @collection.get($(el).parent().attr('id'))

    if el.value is '' and model.get('label') is undefined
      return @collection.remove model
    else if el.value is ''
      value = model.get('label')
    else value = el.value

    model.set('label', value)
    @collection.sync 'update', model
    @collection.save()
    @collection.trigger 'update'

  view: (e) ->
    el = $(e.target)
    return if !el.is('li')

  edit: (e) ->
    el = $(e.target).parent()
    model = @collection.get(el.attr('id'))
    @new(model, el[0])

  delete: (e) ->
    el = $(e.target)
    # if el.find('label').html() is ''
    el.remove()
    @collection.remove(el.attr('id'))
    @save()

  render: (template = @template, data) ->
    data = data or _.sortBy @collection.toJSON(), (i) ->
      -1 * @get(i.id).cid.slice(1) # neweset first
    , @collection

    templateData = _.extend {}, @helpers, loops: data
    html = template.render(templateData)
    @element.html(html)
    return this

  helpers:
    placeholder: -> @label or 'Loop Name'
