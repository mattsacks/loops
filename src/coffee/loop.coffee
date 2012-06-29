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
    'add':    (model) -> @sync('create', model.attributes)
    'remove': (model) -> @sync('delete', model.attributes)
    'reset':  (model) ->
      localStorage.removeItem('loops')
      @localStorage = new Store('loops')
    'change': (model,changes) ->
      for change,bool of changes
        if bool then @sync('update', model.attributes)

  sync: Backbone.sync.store
  save: -> @localStorage.save()

class Loop extends Backbone.Model
  constructor: (attributes, options) ->
    attributes.id or= S4()
    super(attributes, options)

  defaults:
    amount: 0
    data: {}

  # range as 'hour', 'day', 'week', 'month'
  fromReset: (range) ->
    switch range
      when 'days'   then (date) -> +moment(date).sod()
      when 'weeks'  then (date) -> +moment(date).sod().day(0)
      when 'months' then (date) -> +moment(date).sod().date(1)

  resetByRange: (range, point, reset) ->
    time = +point.time
    if range is 'week'
      i = +moment(time).format("w")
    else
      i = +moment(time)[range]()

    +moment(reset(time))[range](i).sod()

  createBins: (range) ->
    @dateReset = @fromReset(range)
    
    bins = []
    diff = moment(@endTime).sod().diff(moment(@startTime).sod(), range)
    if diff is 0 then diff is 1 # get at least one bin dammit
    start = @dateReset(@startTime) # origin date, reset / basis (first of month, etc)

    bins.push +moment(start).add(range, i) for i in [0..diff]
    return bins

  migrate: (schemas, mappings, labels) ->
    return if arguments.length is 0

    data = {}
    for label of labels
      bins = labels[label]
      if bins?
        # set the label property as an array of the passed in bins
        data[label] = new Array(bins.length)

        for i in [0..bins.length]
          # create a data object for the data property, set it's label to be
          # the bin value and merge in any other properties attributed to the
          # label from the schema
          data[label][i] = _.extend (label: bins[i]), schemas[label]
      else
        # otherwise just set create an array of the values
        data[label] = new Array(@modelData.length)

    # each data point saved for this loop
    for x in @modelData
      for key, mapping of mappings
        bins = labels[key]
        if labels[key]? and schemas[key]?
          index = bins.indexOf(mapping(x))
          continue if index is -1
          debugger
          data[key][index].points.push x
          data[key][index].sum += x.val if schemas[key].sum?


  collect: ->
    @modelData  = []
    @modelData.push(time: time, val: val) for time, val of @get('data')
    return if @modelData.length is 0
    @start = @modelData[0]
    @startTime = +@start.time; @start = @start.val

    if @modelData.length > 1
      @end     = _.last(@modelData)
      @endTime = +@end.time; @end = @end.val

    # collect data.day   as [12am,1am,2am...11pm]
    dayBins   = @createBins('days')
    dayReset  = @dateReset
    # collect data.week  as [sunday,monday,tuesday...saturday]
    weekBins  = @createBins('weeks')
    weekReset = @dateReset
    # collect data.month as [6/1,6/2...6/30]
    monthBins  = @createBins('months')
    monthReset = @dateReset
    
    schemas =
      days:   by: 'days',   points: [], sum: 0
      weeks:  by: 'weeks',  points: [], sum: 0
      months: by: 'months', points: [], sum: 0

    mappings =
      days:   (p) => +@resetByRange('day', p, dayReset)
      weeks:  (p) => +@resetByRange('week', p, weekReset)
      months: (p) => +@resetByRange('month', p, monthReset)

    labels =
      days:    dayBins
      weeks:   weekBins
      months: monthBins

    return @migrate(schemas, mappings, labels)

