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
    'change': (model,changes) ->
      for change,bool of changes
        if bool then @sync('update', model)

  sync: Backbone.sync.store
  save: -> @localStorage.save()

class Loop extends Backbone.Model
  constructor: (attributes, options) ->
    attributes.id or= S4()
    super(attributes, options)
