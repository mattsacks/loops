class TimeSeries # extends BaseGraph
  constructor: (options) ->
    options = _.extend {}, @defaults, options
    this[key] = option for key, option of options

    @gather()
    @addEvents()

  gather: ->
    @graph = d3.select('#loop-graph')

    @$graph = $(@graph.node())
    # blast, doesn't work on svg for iphone and probably ipad so im screwed
    @graph.height = @$graph.height() or 160
    @graph.width  = @$graph.width()  or 320

    @range = @view.expandedDetail

  addEvents: ->
    _.bindAll this, 'render'


    @view.on 'render', =>
      @range = @view.model.get('period')
      @render()
    @view.on 'viewChange', (view) =>
      @range = @view.model.get('period')
      @render()

  defaults: {}

  # the string for formatting a moment object
  timeFormat: (range = @range) ->
    switch range
      when 'today' then 'h:mma'  # hour:minuteAM
      when 'hour'  then 'h:mma'  # hour:minuteAM
      when 'day'   then 'M/D'    # MonthN/Date
      when 'week'  then 'MMM Do' # MonthName Date'th
      when 'thisWeek' then 'dddd' # Sunday, Monday
      when 'month' then 'MMM'    # Jan,Feb

  # how to reset a date tick based on the data
  tickFormat: (d, range = @range) ->
    switch range
      when 'today'    then moment(d)
      when 'hour'     then moment().hours(d).minutes(0)
      when 'day'      then moment(d)
      when 'week'     then moment(d)
      when 'thisWeek' then moment().day(d)
      when 'month' then moment().month(d)

  # returns an object w/ x and y scales for a time series,
  # along with a line function for computing against those scales
  #
  # data should be an array of bins or array of points
  setScales: (data) ->
    times   = []; sums = []
    wMargin = 50; hMargin = 25
    width   = @graph.width  - wMargin
    height  = @graph.height - hMargin

    _.each data, (x) -> # one passsssssss
      times.push +(x.time or x.label)
      sums.push  x.val or x.sum

    x = d3.scale.linear() # time from first point -> last
      # from the start of the data to the end
      .domain(d3.extent(times))
      .range([wMargin, width])

    y = d3.scale.linear()
      # from most accumulated to least
      .domain(d3.extent(sums))
      .range([height, hMargin])

    line = d3.svg.line()
      .x((p) -> +(p.time or p.label))
      .y((p) -> p.val or p.sum)

    return x: x, y: y, line: line

  # draws axes according to a scale configuration object and the passed in data
  drawAxes: (scales, data) ->
    xAxis = # unless an axis object already exists with an xAxis
      if @axes?.xAxis? then @axes.xAxis
      else
        @graph
          .append('g')
          .attr('class', 'ticks xTicks')
          .attr('transform', "translate(0, #{scales.y.range()[0]})")

    # if an axis object already exists with xTicks, then remove them
    if @axes?.xTicks? then @axes.xTicks.remove()

    nTicks = if window.mobile is true then 3 else 6
    # make at most the length of data, else 6
    nTicks = data.length if nTicks > data.length
    xTickData = scales.x.ticks(nTicks)
    if xTickData.length is 0 then return

    xTicks = xAxis
      .selectAll('g')
      .data(xTickData)
      .enter()
      .append('g')
      .attr('class', 'tick')
      .attr('transform', (d) ->
        "translate(#{scales.x(d)}, 0)")

    timeFormat = @timeFormat()
    xTicks
      .append('svg:text')
      .text((d) =>
        @tickFormat(d).format(timeFormat))

    return {
      xAxis: xAxis
      xTicks: xTicks
    }

  drawTimeSeries: (scales, data) ->
    if @nodes? then @nodes.remove()

    @nodes = @graph
      .selectAll('.point')
      .data(data)

    @nodes
      .enter()
      .append('svg:circle')
      .attr('class', 'point')
      .attr('r', 4)
      .attr('cx', (d) ->
        scales.x(+(d.time or d.label)))
      .attr('cy', (d) ->
        scales.y(d.val or d.sum))

  render: ->
    data = @view.latestTemplateData.modelData
    return if !data? # don't draw anything...

    data =
      # a necessary evil
      if @range is 'today' then data.today[0].points
      else if @range is 'thisWeek' then data.thisWeek
      else data[@range] or data[@range + 's']

    @scales = @setScales(data)
    @axes   = @drawAxes(@scales, data)

    # TODO make this variable to graph type based on @range
    @timeseries = @drawTimeSeries(@scales, data)
