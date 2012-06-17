_.extend Backbone.Model.prototype,
  getValue: (object, prop) ->
    if (!object and object[prop]) then null 
    else if _.isFunction(object[prop]) then object[prop].apply(this) else object[prop]
  get: (attr) -> @getValue(@attributes, attr)

class Loops extends Backbone.Collection
  constructor: (models, options = {}) ->
    @model = Loop
    super(models, options)

    @on(event, run) for event, run of @events

  parse: 'loops'
  localStorage: new Store('loops')

  events:
    'add': (model) ->
      @sync('create', model)
      @sync('update', this)

  sync: Backbone.sync.store

class Loop extends Backbone.Model
  defaults:
    id: -> @cid.match(/\d+/)[0]

  idAttribute: 'id()'

class LoopView extends Backbone.View
  constructor: (collection, options = {}) ->
    _.extend options, @defaults
    super(options)
    @collection = collection
    @template = Hogan.compile($("##{options.templateId}").html())

  el: '#loops'

  defaults:
    templateId: 'loop-template'

  render: ->
    debugger
    html = @template.render()
    this.$el.html(html)

$ -> # document.ready
  # window.session = new Session(data.session)
  window.loops    = new Loops()
  window.loopView = new LoopView(loops).render()

  $(document.body).addClass('show')
