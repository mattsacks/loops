class Graph
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
      when 'today'    then 'h:mma'  # hour:minuteAM
      when 'hours'
        if window.mobile is true then 'h' else 'h:mma' # hour:minuteAM
      when 'days'     then 'M/D'    # MonthN/Date
      when 'weeks'    then 'MMM Do' # MonthName Date'th
      when 'thisWeek'
        if window.mobile is true then 'ddd' else 'dddd' # Sunday, Monday
      when 'months'   then 'MMM'    # Jan,Feb

  # how to reset a date tick based on the data
  tickFormat: (d, data) ->
    switch @range
      when 'today'    then moment(d)
      when 'hours'    then moment().hours(d).minutes(0)
      when 'days'     then moment(d)
      when 'weeks'    then moment(d)
      when 'thisWeek' then moment().day(d)
      when 'months'   then moment(d)

  findBins: (range = @range)->
    if range is 'hours'  then d3.range(24)
    else if range is 'thisWeek' then d3.range(7)
    else @view.model.createBins(range) # histogram 

  # returns an object w/ x and y scales for a time series,
  # along with a line function for computing against those scales
  #
  # data should be an array of bins or array of points
  setScales: (data) ->
    times   = []; sums = []
    @margin = if window.mobile is true then 20 else 50
    width   = @graph.width  - @margin
    height  = @graph.height - @margin

    _.each data, (x) -> # one passsssssss
      times.push +(x.time or x.label)
      sums.push  x.val or x.sum

    if sums.length is 0 then sums = [0, 0]

    if @range is 'today'
      # adds the last 4 minutes from right now to the times array
      addMinutes = ->
        for i in [1..4]
          times.unshift(+moment().subtract('minutes', i))

      # time ticks should be right now to first entry
      if (data.length)
        # if now to first entry is < 4 minutes, then add those increments
        if moment(+_.last(data).time).diff(+data[0].time, 'minutes') <= 2
          addMinutes()
      # if no entry saved yet, then last 4 minutes
      else addMinutes()
      times.unshift(+moment()) # from now bitch

    x = d3.scale.linear() # time from first point -> last
      # from the start of the data to the end
      .domain(d3.extent(times))
      .range([@margin, width])

    y = d3.scale.linear()
      # from most accumulated to least
      .domain(d3.extent(sums))

    # if only one sum, set minimum domain as 0
    [yMin, yMax] = y.domain()
    y.domain([0, yMax]) if yMin is yMax

    # inverse y scale
    negY = y.copy().range([@margin, height])

    marginY = y.copy().range([height - @margin, @margin/2])
    line = d3.svg.line()
      .x((p) -> x(+(p.time or p.label)))
      .y((p) -> marginY(p.val or p.sum))

    area = d3.svg.area()
      .x((p) -> x(+(p.time or p.label)))
      .y0(height)
      .y((p) -> y(p.val or p.sum))

    return x: x, y: y, marginY: marginY, negY: negY, line: line, area: area

  # draws axes according to a scale configuration object and the passed in data
  drawXTicks: (scales, data) ->
    xAxis = @graph
      .append('g')
      .attr('class', 'ticks xTicks')
      .attr('transform', "translate(0, #{@graph.height-5})")

    if @range is 'today' # timeseries
      ticks =
        if window.mobile is true then scales.x.ticks(5)
        else scales.x.ticks(14)
      x = scales.x
      translate = (d) -> "translate(#{x(d)}, 0)"
    else # histogram
      ticks = @findBins()
      x = d3.scale.ordinal()
        .domain(d3.range(data.length))
        .rangeBands([0, @graph.width], 0.001)
      translate = (d) -> "translate(#{x(d)+x.rangeBand()/2}, 0)"

    xTicks = xAxis
      .selectAll('g')
      .data(ticks)
      .enter()
      .append('g')
      .attr('class', 'tick')
      .attr('transform', (d) -> translate(d))

    timeFormat = @timeFormat()
    # how many ticks to append
    mod = switch @range
      # every other hour
      when 'hours' then 2
      # for the day ticks (m/dd), every other one per 10 days
      when 'days' then Math.floor(data.length / 10) || 1
      else 1
    xTicks
      .filter((d,i) -> return i % mod is 0)
      .append('svg:text')
      .text((d,i) =>
        time = @tickFormat(d)
        if time is false then return ''
        if @range is 'hours' and window.mobile is true
          timeFormat = if moment(time).hours() < 12 then 'h[a]' else 'h[p]'
        return time.format(timeFormat))

    # add ruler lines for the timeseries
    if @range is 'today'
      xTicks.append('svg:line')
        .attr('class', 'ruler')
        .attr('y1', '-15')
        .attr('y2', '-275')

    return xTicks

  drawTimeSeries: (scales, data) ->
    yAxis = @graph
      .append('g')
      .attr('class', 'ticks yTicks')

    if window.mobile is true
      ticks = scales.y.ticks(10)
      scales.x.range([@margin + 10, @graph.width - @margin])
    else
      ticks = scales.y.ticks(5)

    yTicks = yAxis
      .selectAll('g')
      .data(ticks)
      .enter()
      .append('g')
      .attr('class', 'tick')
      .attr('transform', (d) -> "translate(10, #{scales.marginY(d)})")

    yTicks
      .append('svg:text')
      .attr('dy', 5)
      .text(d3.format('d'))
    yTicks
      .append('svg:line')
      .attr('class', 'ruler')
      .attr('x1', 10)
      .attr('x2', @graph.width - 20)
      .attr('transform', 'translate(0, 2)')

    @line = @graph
      .selectAll('path')
      .data([data])
      .enter()
      .append('svg:path')

    @nodes = @graph
      .selectAll('.point')
      .data(data)
      .enter()
      .append('svg:circle')
      .attr('class', 'point')

    draw = (k) =>
      # draw the line with data from 0 -> interval
      @line.attr 'd', (d) => scales.line(d.slice(0, k))

      node = d3.select(@nodes[0][k]) # this interval's node

      node
        .attr('cx', (d) -> scales.x(+(d.time or d.label)))
        .attr('cy', (d) -> scales.marginY(d.val or d.sum))
        .attr('r', 5)
        .transition()
        .duration(400)
        # return an interpolater for the values from 10 to 5 for the radius of
        # the node 
        .attrTween 'r', (d) => (t) -> d3.interpolate(10, 5)(t)

      return false

    k = 0
    d3.timer =>
      if k is data.length + 1 then return true
      else draw(k++)

  drawHistogram: (scales, data) ->
    thiz  = this
    height = @graph.height - (@margin/2)
    if window.mobile is true then height -= 10 # shitty
    y = scales.y.copy()
      .domain([0, scales.y.domain()[1]])
      .range([10, height])

    x = d3.scale.ordinal()
      .domain(d3.range(data.length))
      .rangeBands([0, @graph.width], 0.004)

    histogram = @graph
      .append('g')
      .attr('class', 'histogram')
      # bottom left origin
      .attr('transform', "translate(0,#{height}) scale(1,-1)")

    bar = histogram.selectAll('.bar')
      .data(data)
      .enter()
      .append('svg:g')
      .attr('class', 'bar')
      .attr 'transform', (d,i) -> "translate(#{x(i)}, 0)"

    # requires the text to be separately manipulated because i have no clue how
    # to anchor the y to the bottom of the rect in a reverse scale
    bar.append('svg:rect')
      .attr('width', x.rangeBand())
      .attr('height', 0)
      .each((d,i) -> d3.select(this)
        .transition()
        .delay((600 / data.length)*i)
        .duration(175)
        .attr('height', (d) -> y(d.val or d.sum)))

    tickOffset = if window.mobile is true then 15 else 20
    bar.append('svg:text')
      .attr('class', 'tick')
      .attr('x', x.rangeBand()/2)
      .attr('y', 0)
      .attr('transform', 'scale(1, -1)') # flip the text back
      .each((d,i) ->
        return if d.val is 0 or d.sum is 0
        d3.select(this)
          .transition()
          .delay((600 / data.length)*i)
          .duration(175)
          .text(d.val or d.sum)
          .attr('y', (d) ->
            height = d.val or d.sum
            return -1 * y(height) + tickOffset))

  render: ->
    data = @view.latestModelData
    return if !data? # don't draw anything...

    data =
      # a necessary evil
      if @range is 'today' then data.today[0].points
      else if @range is 'thisWeek' then data.thisWeek
      else data[@range]

    @graph.selectAll('*').remove()

    @scales = @setScales(data)
    @xTicks = @drawXTicks(@scales, data)

    # TODO make this variable to graph type based on @range
    if @range is 'today'
      @drawTimeSeries(@scales, data)
    else @drawHistogram(@scales, data)
