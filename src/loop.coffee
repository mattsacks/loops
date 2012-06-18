class Loops extends Backbone.Collection
  constructor: (models = [], options = {}) ->
    @model = Loop
    data = _.union models, _.toArray(@localStorage.data)
    super(data, options)

    @localStorage.save()
    @on(event, run) for event, run of @events

  parse: 'loops'
  localStorage: new Store('loops')

  events:
    'add':    (model) -> @sync('create', model)
    'remove': (model) -> @sync('delete', model)
    'reset':  (model) ->
      localStorage.removeItem('loops')
      @localStorage = new Store('loops')

  sync: Backbone.sync.store

class Loop extends Backbone.Model
  constructor: (attributes, options) ->
    attributes.id or= S4()
    super(attributes, options)

class LoopView extends Backbone.View
  constructor: (collection, options = {}) ->
    _.extend options, @defaults
    super(options)
    @collection = collection
    @template = Hogan.compile($("##{options.templateId}").html())

    @gather()
    @attach()
    return this

  gather: ->
    @els =
      new: $('#create')
      newTemplate: $('#loop-new-template')

  attach: ->
    _.bindAll this, 'edit'

    @collection.on 'add', (model) =>
      #@save()
      @new(model)

    @$el.on 'blur', 'input.new', (e) => @save.call(this, e.target)

    @els.new.on 'click', => @collection.add([new Loop({})])

    @collection.on 'update', => @render()
    @collection.on 'reset', => @render()

  el: '#loops'

  events:
    'click label': 'edit'
    'keydown input.new': 'create'

  defaults:
    templateId: 'loop-template'

  new: (model) ->
    template = Hogan.compile(@els.newTemplate.html())
    @$el.prepend(template.render(model.toJSON()))
    @$('input.new').focus()

  create: (e) ->
    console.log(e)

  save: (el, model = _.last(@collection.models)) ->
    model.set('label', el.value)
    @collection.sync 'update', model
    @collection.trigger 'update'

  edit: (e) ->
    el = $(e.target).parent()
    model = @collection.get(el.attr('id'))
    el.remove()
    @new(model)

  render: (template = @template, data) ->
    data = data || _.sortBy @collection.toJSON(), (i) ->
      # neweset first
      -1 * @get(i.id).cid.slice(1)
    , @collection

    html = template.render(loops: data)
    @$el.html(html)
    return this
