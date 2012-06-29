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
    attributes = _.extend {}, # defaults wasn't working or something
      amount: 0
      data: new Object()
    , attributes
    super(attributes, options)

  # range as 'hour', 'day', 'week', 'month'
  rangeReset: (range) ->
    switch range
      when 'days'   then (date) -> +moment(date).sod()
      when 'weeks'  then (date) -> +moment(date).sod().day(0)
      when 'months' then (date) -> +moment(date).sod().date(1)

  # return the of this time's hour/day/week/month to find
  resetByRange: (point, reset) ->
    time = +point.time
    +moment(reset(time))

  # creates n bins from @startTime.diff ['week', 'day'...] to @endTime
  createBins: (range) ->
    reset = this["#{range}Reset"] or= @rangeReset(range)
    
    bins = []
    diff = moment(@endTime).sod().diff(moment(@startTime).sod(), range)
    if diff is 0 then diff is 1 # get at least one bin dammit

    start = reset(@startTime) # origin date, reset/basis (first of month, etc)

    bins.push +moment(start).add(range, i) for i in [0..diff]
    return bins

  # take 3 objects passed in to organize data against, each with the same key
  # to coordinate binning
  # mappings: key: data key, value: function to map on each data point,
  #                          returning a value of which the according bins
  #                          (label[key])to the data key should find
  # (optional arguments)
  # schemas: key: data key, value: object to map default properties to each bin
  # labels: key: data key, value: an array of bins to which each value will be
  #                        the label of the bin. ex: a numerical date for each
  #                        day of the week or a category name
  migrate: (mappings, schemas, labels) ->
    return if arguments.length is 0

    data = {}
    for key, mapping of mappings
      bins = labels[key]
      if bins?
        # set the label property as an array of the passed in bins
        data[key] = new Array(bins.length)

        for i in [0...bins.length]
          # copy is necessary because arrays are otherwise the same reference
          data[key][i] = _.copy(_.extend({}, schemas[key]), (label: bins[i]))
      else
        # otherwise just set create an array of the values
        data[key] = new Array(@modelData.length)

    # each data point saved for this loop
    for x,i in @modelData
      for key, mapping of mappings
        bins = labels[key]
        if labels[key]? and schemas[key]?
          index = bins.indexOf(mapping(x))
          continue if index is -1
          data[key][index].points.push x
          data[key][index].sum += x.val if schemas[key].sum?

        else data[key][i] = mapping(x,i)

    return data

  # organize raw JSON data into a collection of bins, either across properties
  # or dates. return an object representing all data in this loop
  collect: ->
    @modelData  = []
    @modelData.push(time: time, val: val) for time, val of @get('data')
    return if @modelData.length is 0
    @start = @modelData[0]
    @startTime = +@start.time; @start = @start.val

    if @modelData.length > 1
      @end     = _.last(@modelData)
      @endTime = +@end.time; @end = @end.val

    # collect data.today as [12am, 1am, 2am...11pm]
    todaysBins = [0..moment().hours()] # from 12am to this hour
    # collect data.day   as [3/1, 3/2, 3/3..today]
    dayBins    = @createBins('days')
    # collect data.week  as [2 weeks ago, last week, this week]
    weekBins   = @createBins('weeks')
    # collect data.month as [6/1,7/1,8/1,this month]
    monthBins  = @createBins('months')
    
    schemas =
      today:  { by: 'hour',  points: [], sum: 0 }
      days:   { by: 'day',   points: [], sum: 0 }
      weeks:  { by: 'week',  points: [], sum: 0 }
      months: { by: 'month', points: [], sum: 0 }

    # day-of-year, default: today
    doy = (point = undefined) -> +moment(point).format("DDD")
    mappings =
      vals:   (p) -> p.val
      today:  (p) ->
        # if this point wasnt recorded today, don't include it
        return '#!@*' if doy(+p.time) isnt doy()
        +moment(+p.time).hours() # return the 24-base hour the point was recorded

      # returns the point.time reset to the beginning of the ['day', 'week', 'month']
      # so that'd be 12am, sunday, the first
      days:   (p) => +@resetByRange(p, @daysReset)
      weeks:  (p) => +@resetByRange(p, @weeksReset)
      months: (p) => +@resetByRange(p, @monthsReset)

    labels =
      today:  todaysBins
      days:      dayBins
      weeks:    weekBins
      months:  monthBins

    return @latestData = @migrate(mappings, schemas, labels)

