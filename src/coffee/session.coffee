class Session extends Backbone.Model
  constructor: (@viewNames...) ->
    super(@localStorage.data)
    @save()

    # attach hooks into the 'render' event for each registered view passed in
    # to the constructor
    window[view].on(event, run, this) for event, run of @viewEvents for view in @viewNames

    @view  = window[@get('view')] # collect the current view from localStorage

    if !@view? # show the default view if none was previously found
      view = @viewNames[0] # this should be the loopsView, the first argument
      @sync.apply(this, ['create', view, id: 'view'])
      @set('view', @view = window[view]) # set @view while setting it

    @views = [] # cache the instantiated objects of the registered viewNames
    @views.push(window[i]) for i in @viewNames

    @model = @get('model') # set the model if one was found from the data
    if @model # restore that model's view
      @view.restore(@view.collection.get(@model.id), @get('graph'))
    else @view.restore() # otherwise, just call restore on the set (or default) @view

  # events fired on each registered view in @views from @viewNames passed in
  viewEvents:
    # on the 'render' event for each view
    'render': (@view, data) ->
      viewName = @viewNames[@views.indexOf(@view)]

      # update the viewName in storage as 'view'
      @sync.apply(this, ['update', viewName, id: 'view'])

      # update the data if present, otherwise delete it
      sync = (op, data) =>
        @sync.apply(this, [op, datum, id: key]) for key,datum of data
      if data? then sync('update', data) else sync('delete', @localStorage.data)

  localStorage: new Store('loops-session')
  sync: Backbone.sync.store
  save: -> @localStorage.save()
