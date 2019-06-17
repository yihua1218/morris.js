# Donut charts.
#
# @example
#   Morris.Donut({
#     el: $('#donut-container'),
#     data: [
#       { label: 'yin',  value: 50 },
#       { label: 'yang', value: 50 }
#     ]
#   });
class Morris.Donut extends Morris.EventEmitter
  defaults: {
    colors: [
      '#0B62A4'
      '#3980B5'
      '#679DC6'
      '#95BBD7'
      '#B0CCE1'
      '#095791'
      '#095085'
      '#083E67'
      '#052C48'
      '#042135'
    ],
    backgroundColor: '#FFFFFF',
    labelColor: '#000000',
    formatter: Morris.commas
    resize: false,
    cursor: 'pointer'
  }
  # Create and render a donut chart.
  #
  constructor: (options) ->
    return new Morris.Donut(options) unless (@ instanceof Morris.Donut)
    @options = $.extend {}, @defaults, options

    if typeof options.element is 'string'
      @el = $ document.getElementById(options.element)
    else
      @el = $ options.element

    if @el == null || @el.length == 0
      throw new Error("Graph placeholder not found.")

    # bail if there's no data
    if @options.data is undefined or @options.data.length is 0
      return

    @raphael = new Raphael(@el[0])

    if @options.resize
      $(window).bind 'resize', (evt) =>
        if @timeoutId?
          window.clearTimeout @timeoutId
        @timeoutId = window.setTimeout @resizeHandler, 100
    @setData @options.data

    if typeof @options.defaultLabel != 'undefined' and
    @data[@options.defaultLabel]
      row = @data[@options.defaultLabel]
      @setLabels(row.label, @options.formatter(row.value, row), row.labelColor)
      s.deselect() for s in @segments

  # Clear and redraw the chart.
  redraw: ->
    @raphael.clear()

    cx = @el.width() / 2
    cy = @el.height() / 2
    # defaultWidth = 180
    # defaultHeight = 258
    # if !cx
    #   cx = defaultWidth
    # if !cy
    #   cy = defaultHeight

    total = 0
    total += value for value in @values

    minWidth = 5

    if typeof @options.minWidth != 'undefined'
      minWidth = @options.minWidth

    w = Math.abs((Math.min(cx, cy) - 10) / 3)
    min = minWidth / (2 * w)
    C = Math.abs(1.9999 * Math.PI - min * @data.length)
    last = 0
    idx = 0
    @segments = []

    for value, i in @values
      if total is 0
        total = value = 1
      next = last + min + C * (value / total)
      seg = new Morris.DonutSegment(
        cx, cy, w * 2, w, last, next,
        @data[i].color || @options.colors[idx % @options.colors.length],
        @options.backgroundColor, idx, @options.strokeWidth, @raphael, @options.cursor)
      seg.render()
      @segments.push seg
      seg.on 'hover', @select
      seg.on 'click', @click
      last = next
      idx += 1

    labelFontSizeText1 = 15
    labelFontSizeText2 = 14

    if @options.labelFontSize and @options.labelFontSize.text1
      labelFontSizeText1 = @options.labelFontSize.text1

    if @options.labelFontSize and @options.labelFontSize.text2
      labelFontSizeText2 = @options.labelFontSize.text2

    labelColor = @options.labelColor

    if @options.overwriteLabel and @options.overwriteLabel.labelColor
      labelColor = @options.overwriteLabel.labelColor

    @text1 = @drawEmptyDonutLabel(cx, cy - 10,
      labelColor, labelFontSizeText1, 800)
    @text2 = @drawEmptyDonutLabel(cx, cy + 10,
      labelColor, labelFontSizeText2)

    max_value = Math.max @values...
    idx = 0
    for value in @values
      if value == max_value
        @select idx
        break
      idx += 1

  hasOnlyOneSegment: (values) ->
    return values.length is 1 or values.filter((value)->
      value isnt 0
    ).length is 1

  isAllValuesEmpty: (values) ->
    return values.every((value)->
      value is 0
    )

  setData: (data) ->
    @data = data
    @values = (parseFloat(row.value) for row in @data)
    if @hasOnlyOneSegment(@values) or @isAllValuesEmpty(@values)
      @options.strokeWidth = 0
    @redraw()

  # @private
  click: (idx) =>
    @fire 'click', idx, @data[idx]

  # Select the segment at the given index.
  select: (idx) =>
    s.deselect() for s in @segments
    segment = @segments[idx]

    if segment
      segment.select()
      row = @data[idx]
      _fill_color = row.labelColor or @options.labelColor or '#5C5C5C'

      if typeof @options.lockLabel != 'undefined' and
      @data[@options.lockLabel]
        row = @data[@options.lockLabel]

      @setLabels(row.label, @options.formatter(row.value, row), _fill_color)

  deselect: =>
    s.deselect() for s in @segments


  # @private
  setLabels: (label1, label2, fill_color) ->
    if @options.overwriteLabel
      label1 = @options.overwriteLabel.label
      label2 = @options.overwriteLabel.value

    if @options.exchangeLabel
      l1 = label1
      l2 = label2
      label1 = l2
      label2 = l1
    _default_fill = fill_color or '#5C5C5C'
    inner = (Math.min(@el.width() / 2, @el.height() / 2) - 10) * 2 / 3
    maxWidth = 1.8 * inner
    maxHeightTop = inner / 2
    maxHeightBottom = inner / 3
    @text1.attr({ text: label1, transform: '', fill: fill_color })
    text1bbox = @text1.getBBox()
    text1scale = Math.min(
      maxWidth / text1bbox.width,
      maxHeightTop / text1bbox.height)
    if text1scale > 0
      @text1.attr({
        transform: "S#{text1scale},#{text1scale}," +
          "#{text1bbox.x + text1bbox.width / 2}," +
          "#{text1bbox.y + text1bbox.height}",
        cursor: "text"
      })
    @text2.attr({ text: label2, transform: '', fill: fill_color })
    text2bbox = @text2.getBBox()
    text2scale = Math.min(
      maxWidth / text2bbox.width,
      maxHeightBottom / text2bbox.height)
    if text2scale > 0
      @text2.attr({
        transform: "S#{text2scale},#{text2scale}," +
        "#{text2bbox.x + text2bbox.width / 2},#{text2bbox.y}",
        cursor: "text"
      })

  drawEmptyDonutLabel: (xPos, yPos, color, fontSize, fontWeight) ->
    text = @raphael.text(xPos, yPos, '')
      .attr('font-size', fontSize)
      .attr('fill', color)
    text.attr('font-weight', fontWeight) if fontWeight?
    return text

  resizeHandler: =>
    @timeoutId = null
    @raphael.setSize @el.width(), @el.height()
    @redraw()


# A segment within a donut chart.
#
# @private
class Morris.DonutSegment extends Morris.EventEmitter
  constructor: (@cx, @cy, @inner, @outer, p0, p1,
  @color, @backgroundColor, @index, @strokeWidth, @raphael, @cursor) ->
    @sin_p0 = Math.sin(p0)
    @cos_p0 = Math.cos(p0)
    @sin_p1 = Math.sin(p1)
    @cos_p1 = Math.cos(p1)
    @is_long = if (p1 - p0) > Math.PI then 1 else 0
    @path = @calcSegment(@inner + 3, @inner + @outer - 5)
    @selectedPath = @calcSegment(@inner + 3, @inner + @outer)
    @hilight = @calcArc(@inner)

  calcArcPoints: (r) ->
    return [
      @cx + r * @sin_p0,
      @cy + r * @cos_p0,
      @cx + r * @sin_p1,
      @cy + r * @cos_p1]

  calcSegment: (r1, r2) ->
    [ix0, iy0, ix1, iy1] = @calcArcPoints(r1)
    [ox0, oy0, ox1, oy1] = @calcArcPoints(r2)
    return (
      "M#{ix0},#{iy0}" +
      "A#{r1},#{r1},0,#{@is_long},0,#{ix1},#{iy1}" +
      "L#{ox1},#{oy1}" +
      "A#{r2},#{r2},0,#{@is_long},1,#{ox0},#{oy0}" +
      "Z")

  calcArc: (r) ->
    [ix0, iy0, ix1, iy1] = @calcArcPoints(r)
    return (
      "M#{ix0},#{iy0}" +
      "A#{r},#{r},0,#{@is_long},0,#{ix1},#{iy1}")

  render: ->
    @arc = @drawDonutArc(@hilight, @color)
    @seg = @drawDonutSegment(
      @path,
      @color,
      @backgroundColor,
      @cursor,
      => @fire('hover', @index, event),
      => @fire('hoverout', @index, event),
      => @fire('click', @index, event),
      => @fire('mousemove', @index, event)
    )

  drawDonutArc: (path, color) ->
    @raphael.path(path)
      .attr({ stroke: color, 'stroke-width': 2, opacity: 0 })

  drawDonutSegment: (path, fillColor, strokeColor, cursor
  hoverFunction, hoveroutFunction, clickFunction, mousemoveFunction) ->
    strokeWidth = 3

    if typeof @strokeWidth != 'undefined'
      strokeWidth = @strokeWidth

    @raphael.path(path)
      .attr({
        fill: fillColor,
        stroke: strokeColor,
        'stroke-width': strokeWidth,
        cursor: cursor
      })
      .hover(hoverFunction, hoveroutFunction)
      .click(clickFunction)
      .mousemove(mousemoveFunction)

  select: =>
    unless @selected
      @seg.animate({ path: @selectedPath }, 150, '<>')
      @arc.animate({ opacity: 1 }, 150, '<>')
      @selected = true

  deselect: =>
    if @selected
      @seg.animate({ path: @path }, 150, '<>')
      @arc.animate({ opacity: 0 }, 150, '<>')
      @selected = false
