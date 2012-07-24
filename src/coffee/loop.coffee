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
    'change': (model, changes) ->
      for change, bool of changes
        if bool then @sync('update', model.attributes)

  sync: Backbone.sync.store
  save: -> @localStorage.save()

class Loop extends Backbone.Model
  constructor: (attributes, options) ->
    attributes.id or= S4() # provided by Backbone.sync.store
    attributes = _.extend {}, # defaults wasn't working or something
      amount: 0
      data: new Object()
      range:  'day'
      period: 'today'
    , attributes
    super(attributes, options)

  # range as 'hour', 'day', 'week', 'month'
  rangeReset: (range) ->
    switch range
      when 'hours'  then (date) -> +moment(date).hours()
      when 'days'   then (date) -> +moment(date).sod()
      when 'weeks'  then (date) -> +moment(date).sod().day(0)
      when 'months' then (date) -> +moment(date).sod().date(1)
      else (date) -> +date

  # return the of this time's hour/day/week/month to find
  resetRange: (point, reset) ->
    time = +point.time
    +moment(reset(time))

  # creates n bins from @startTime.diff ['week', 'day'...] to @endTime
  createBins: (range) ->
    reset = this["#{range}Reset"] or= @rangeReset(range)

    bins = []
    start = reset(@startTime)
    end   = reset(@endTime)

    diff = moment(end).diff(moment(start), range)
    if diff is 0 then diff is 1 # get at least one bin dammit

    bins.push +moment(start).add(range, i) for i in [0..diff]
    return bins

  # take 3 objects passed in to organize data against, each with the same key
  # to coordinate binning
  # mappings: key: data key, value: function to map on each data point,
  #                          returning a value of which the according bins
  #                          (label[key])to the data key should find
  # (optional arguments)
  # schemas: key: data key, value: object to map default properties to each bin
  # labels: key:  data key, value: an array of bins to which each value will be
  #                         the label of the bin. ex: a numerical date for each
  #                         day of the week or a category name
  migrate: (mappings, schemas, labels, modelData = @modelData) ->
    return if arguments.length is 0

    data = {}
    for key, mapping of mappings
      bins = labels[key]
      if bins?
        # set the label property as an array of the passed in bins
        data[key] = new Array(bins.length)

        for i in [0...bins.length]
          # copy is necessary because arrays are otherwise the same reference
          data[key][i] = _.copy(_.extend({}, schemas[key], (label: bins[i])))
      else
        # otherwise just set create an array of the values
        data[key] = new Array(@modelData.length)

    # each data point saved for this loop
    for x,i in modelData
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
    if @modelData.length isnt 0
      @start = @modelData[0]
      @startTime = +@start.time; @start = @start.val
    else @startTime = +new Date()

    if @modelData.length > 1 then @endTime = +new Date()

    # collect data.hours as [12am, 1am, 2am...11pm]
    hourBins    = d3.range(24)
    @hoursReset = @rangeReset('hours')
    # collect data.day   as [3/1, 3/2, 3/3..today]
    dayBins    = @createBins('days')
    # collect data.week  as [2 weeks ago, last week, this week]
    weekBins   = @createBins('weeks')
    # collect data.month as [6/1,7/1,8/1,this month]
    monthBins  = @createBins('months')

    schemas =
      today:    { by: 'today', points: [], sum: 0 }
      hours:    { by: 'by hour',  points: [], sum: 0 }
      days:     { by: 'by day',   points: [], sum: 0 }
      weeks:    { by: 'by week',  points: [], sum: 0 }
      months:   { by: 'by month', points: [], sum: 0 }

    # day-of-year, default: today
    doy = (point = undefined) -> +moment(point).format("DDD")
    sod = +moment().sod() # start of today
    mappings =
      today:  (p) ->
        time = +p.time
        # if this point wasnt recorded today, don't include it
        if doy(time) isnt doy() then return '#!@*'
        return sod # raw dogg the first one

      # returns the point.time reset to the beginning of the ['day', 'week', 'month']
      # so that'd be 12am, sunday, the first
      hours:  (p) => +@resetRange(p, @hoursReset)
      days:   (p) => +@resetRange(p, @daysReset)
      weeks:  (p) => +@resetRange(p, @weeksReset)
      months: (p) => +@resetRange(p, @monthsReset)

    labels =
      today:  [+moment().sod()]
      hours:  hourBins
      days:   dayBins
      weeks:  weekBins
      months: monthBins

    return @latestData = @migrate(mappings, schemas, labels)

  # runs a mapping of schemapping over each bin in the passed in data set
  #
  # data: an array of objects, each with a similar data scheme
  # schemappings: a configuration object of data key -> mapping performed on each bin
  #   arguments to the mapping: the bin itself, the bin index, and the entire data collection
  collectTotals: (data, schemappings) ->
    for index in [0...data.length]
      bin = data[index]
      for prop, mapping of schemappings
        val = mapping(bin, index, data)
        bin[prop] = val if val? # only set the property if it's returned something

    return data
