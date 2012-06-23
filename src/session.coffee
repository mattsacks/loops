class Session extends Backbone.Model
  constructor: (@viewNames...) ->
    super(@localStorage.data)
    @save()

    window[view].on(event, run, this) for event, run of @viewEvents for view in @viewNames
    #@on(event, run) for event, run of @events

    @view  = window[@get('view')]
    if !@view? #default
      view = @viewNames[0]
      @sync.apply(this, ['create', view, id: 'view'])
      @set('view', window[view])

    @views = []
    @views.push(window[i]) for i in @viewNames

    @model = @get('model')
    if @model
      @view.restore(@view.collection.get(@model.id))
    else @view.restore()

  viewEvents:
    'render': (view, model) ->
      viewName = @viewNames[@views.indexOf(view)]
      @sync.apply(this, ['update', viewName, id: 'view'])
      if model? then @sync.apply(this, ['update', model, id: 'model'])
      else @sync.apply(this, ['delete', model, id: 'model'])

  localStorage: new Store('loops-session')
  sync: Backbone.sync.store
  save: -> @localStorage.save()
