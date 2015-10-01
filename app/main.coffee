require.config
  baseDir: 'app'
  shim: bootstrap: deps: [ 'jquery' ]
  paths:
    jquery: 'vendor/jquery/dist/jquery'
    bootstrap: 'vendor/bootstrap/dist/js/bootstrap'
    handlebars: 'vendor/handlebars/handlebars'
    d3: 'vendor/d3/d3'
    'd3-tip': 'vendor/d3-tip/index'
require [
  'jquery'
  'bootstrap'
  'handlebars'
  'd3'
  'd3-tip'
], ($, bootstrap, Handlebars, d3, d3Tip) ->

  nameToId = (name) ->
    name.replace(/\W+|\s+/g, '-').toLowerCase().replace /-$/, ''

  filters = 
    'client-web-framework': 'SPA Framework'
    'css-authoring': 'CSS Authoring'
    'js-library': 'JS Library'
    'rwd-css-frameworks': 'RWD Frameworks'
    'server-web-framework': 'Web Framework'
    'web-components': 'Web Components'
    'micro-framework': '&mu; Frameworks'
  footer = Handlebars.compile($('#footer-tmpl').html())

  captialize = (s) ->
    if undefined == s
      return s
    s.substring(0, 1).toUpperCase() + s.substring(1)

  $('footer').html footer(year: (new Date).getFullYear())
  d3.csv('app/csv/fwk-infographic.csv').get (err, rows) ->

    cumulative = (i) ->
      splits.slice(0, i).reduce ((a, b) ->
        a + b
      ), 0

    if err
      throw err
    m = {}
    # get unique elements in order
    order = [
      'tech-trigger'
      'inflated-expectations'
      'disillusionment-trough'
      'enlightenment-slope'
      'productivity-plateau'
    ]
    rows.forEach (r) ->
      r.id = nameToId(r.name)
      r.excerpt = captialize(r.excerpt)
      r.description = captialize(r.description)
      return
    pps = 0
    ppn = 0
    rows.forEach (row) ->
      a = m[row.bucket] or []
      # my formula (stars/2) + forks + (commits / releases) + (contributors * 10) - openIssues + (tag-toal * 0.8)
      if row.releases != ''
        row.githubScore = Math.ceil(parseInt(row.stars) / 2 + parseInt(row.forks) + (if parseInt(row.releases) == 0 then parseInt(row.commits) else parseInt(row.commits) / parseInt(row.releases)) + parseInt(if row.contributors == '' then '0' else row.contributors) * 10 - parseInt(row.openIssues))
        if row.bucket == 'productivity-plateau'
          pps += row.githubScore
          ppn++
      if row.stackoverflowQuestions != ''
        row.stackoverflowScore = Math.ceil(parseInt(row.stackoverflowQuestions) * 0.8)
      else
        row.stackoverflowScore = 0
      a.push row
      m[row.bucket] = a
      return
    fwks = []
    # ext-js
    order.forEach (grp) ->
      m[grp].forEach (fwk) ->
        if fwk.githubScore == undefined
          fwk.githubScore = Math.ceil(pps / ppn)
        fwk.score = fwk.githubScore + fwk.stackoverflowScore
        return
      fwks = fwks.concat(m[grp])
      return
    order.forEach (grp) ->
      m[grp] = m[grp].sort((a, b) ->
        a.score - (b.score)
      )
      return
    arr = []

    render = ->
      page = $('#page')
      page.empty()
      template = Handlebars.compile($('#grp-tmpl').html())
      order.forEach (grp) ->
        arr = arr.concat(m[grp])
        page.append template(
          groupName: grp.replace(/-/g, ' ')
          frameworks: m[grp])
        return
      return

    render()
    # http://bl.ocks.org/mbostock/1705868
    width = 1000
    height = 600
    color = d3.scale.category20().domain(Object.keys(filters))
    o = d3.scale.ordinal().domain(arr.map((fwk) ->
      fwk.score
    )).rangeRoundPoints([
      0
      50
    ]).range()
    svg = d3.select('#infographic').append('svg').attr('width', width).attr('height', height)
    path = svg.append('path').attr('d', 'm 7.177613,550.54409 c 27.69768,-149.13861 47.544599,-307.80481 99.397767,-452.1335 57.14814,-159.06944 99.25843,30.22313 119.3492,92.155891 20.81677,64.174559 42.49347,128.109889 62.90327,192.397229 48.6483,153.23261 145.3455,-43.20565 169.0116,-77.8645 21.541,-31.54563 38.3884,-74.66755 127.97,-82.51039 128.88667,-11.28411 324.61649,-8.28367 412.26209,-9.86591').style('fill', 'none').attr('stroke', '#000').attr('stroke-width', '1px')
    colors = [
      '#00ced1'
      '#ee82ee'
      '#00ff7f'
      '#ffa07a'
      '#ffd700'
    ]
    colors = [
      '#386cb0'
      '#ffff99'
      '#fdc086'
      '#beaed4'
      '#7fc97f'
    ]
    colors = [
      '#d7191c'
      '#fdae61'
      '#ffffbf'
      '#a6d96a'
      '#1a9641'
    ]
    splits = [
      .1
      .2
      .1
      .2
      .4
    ]
    pn = path.node()
    pathWidth = pn.getBBox().width
    pathLength = pn.getTotalLength()
    # draw background
    backgrounds = svg.append('g').attr('id', 'backgrounds')
    rect = backgrounds.selectAll('rect').data(splits).enter().append('rect').attr('x', (d, i) ->
      cumulative(i) * pathWidth
    ).attr('y', 0).attr('width', (d, i) ->
      d * pathWidth
    ).attr('height', height).style('fill', (d, i) ->
      colors[i]
    ).style('fill-opacity', '.2')
    # write background labels
    initialOffset = 5
    bgTitles = [
      {
        label: 'Technology Trigger'
        orientation: 'vertical'
        align: 'top'
      }
      {
        label: 'Inflated Expectations'
        orientation: 'horizontal'
        align: 'middle'
      }
      {
        label: 'Disillusionment Trough'
        orientation: 'vertical'
        align: 'top'
      }
      {
        label: 'Enlightenment Slope'
        orientation: 'vertical'
        align: 'top'
      }
      {
        label: 'Productivity Plateau'
        orientation: 'horizontal'
        align: 'top'
      }
    ]
    bgTitles.forEach (title, i) ->
      vertical = title.orientation == 'vertical'
      transform = if vertical then 'rotate(-90, 0, 0)' else ''
      txt = backgrounds.append('text').attr('class', 'bucket').style('stroke-width', '0px').style('fill', if i == 2 then '#ffd700' else colors[i]).attr('transform', transform).text(title.label)
      br = txt.node().getBoundingClientRect()
      p = 
        x: cumulative(i) * pathWidth + initialOffset + (if vertical then Math.ceil(br.width) else 0)
        y: if title.align == 'top' then initialOffset + Math.ceil(br.height) else initialOffset + Math.ceil((height - (br.height)) * .7)
      txt.attr 'transform', 'translate(' + p.x + ', ' + p.y + ') ' + transform
      return
    # do some calculation to split the distance by the sections
    dot = svg.append('circle').attr('fill', '#000').attr('r', '5px').attr('stroke-width', '0px')
    offs = []
    x = 0
    i = 0
    sl = splits.length
    while i < sl
      lm = (cumulative(i) + splits[i]) * pathWidth
      x = lm
      xy = pn.getPointAtLength(x)
      dot.attr 'transform', 'translate(' + xy.x + ',' + xy.y + ')'
      if xy.x < lm
        while xy.x < lm
          x += Math.ceil((lm - (xy.x)) / 2)
          xy = pn.getPointAtLength(x)
          dot.attr 'transform', 'translate(' + xy.x + ',' + xy.y + ')'
      else
        while xy.x > lm
          x -= Math.ceil((lm - (xy.x)) / 2)
          xy = pn.getPointAtLength(x)
          dot.attr 'transform', 'translate(' + xy.x + ',' + xy.y + ')'
      offs.push x + 20
      i++
    dot.remove()
    # finished nasty...X|
    circles = svg.append('g').attr('id', 'phases')
    tipTemplate = Handlebars.compile($('#tip-tmpl').html())
    tip = d3Tip().attr('class', 'd3-tip').html((d) ->
      tipTemplate d
    ).direction('s').offset([
      12
      0
    ])
    svg.call tip
    order.forEach (group, i) ->
      `var svg`
      `var dot`
      bucket = circles.append('g').attr('id', group)
      offset = if i == 0 then 0 else offs[i - 1]
      segment = (offs[i] - offset - 20) / m[group].length
      #console.log('offset', offset, 'segment', segment, 'length', (pathWidth * splits[i]), 'gl', m[group].length);
      dot = bucket.selectAll('.fwk').data(m[group]).enter().append('g').attr('id', (d) ->
        nameToId d.name
      ).attr('class', (d) ->
        'fwk ' + d.type.replace(/,/g, ' ') + ' ' + d.language
      ).attr('transform', (d, i) ->
        dist = offset + segment * i
        p = pn.getPointAtLength(dist)
        p1 = pn.getPointAtLength(dist - 20)
        p2 = pn.getPointAtLength(dist + 20)
        angle = Math.atan((p2.y - (p1.y)) / (p2.x - (p1.x))) * 180 / Math.PI + 90
        if d.id == 'wicket'
          console.log d.id, angle
        angle = if angle > 114 or angle < 90 and angle + 5 > 90 then angle - 180 else angle
        'translate(' + p.x + ',' + p.y + ') rotate(' + angle.toFixed(2) + ', 0, 0)'
      ).on('mouseover', tip.show).on('mouseout', tip.hide)
      dot.append('circle').attr('r', '4px').attr 'fill', (d, i) ->
        color d.type.replace(/,.*$/, '')
      dot.append('a').attr('href', (d, i) ->
        d.link
      ).attr('title', (d, i) ->
        d.description
      ).append('text').attr('class', 'fwk-label').attr('transform', 'translate(10, 5)').text (d) ->
        d.name
      return
    # add legend
    s = 200
    filterKeys = Object.keys(filters)
    svg = d3.select('#infographic svg')
    legend = svg.append('g').attr('class', 'legend').attr('transform', 'translate(' + width - s + ',' + height - s + ')')
    #Create the title for the legend
    text = legend.append('text').attr('class', 'title').attr('x', 25).attr('y', 10).style('font-weight', 'bold').style('font-size', '14px').attr('fill', '#404040').text('Legend')
    g = legend.selectAll('g').data(filterKeys).enter().append('g')
    g.attr('class', 'legend-item').attr('transform', (d, i) ->
      'translate(10, ' + i * 10 + 30 + ')'
    ).attr('id', (d, i) ->
      'l-' + d
    ).on 'click', (e) ->
      id = @id.replace(/l-/, '')
      checked = @getAttribute('data-value') == 'checked'
      @setAttribute 'data-value', if checked then 'unchecked' else 'checked'
      display = if checked then 'none' else 'block'
      svg.selectAll('.' + id).style 'visibility', if checked then 'visible' else 'hidden'
      d3.select('#lr-' + id).style 'fill-opacity', if checked then 1 else 0
      return
    g.append('rect').attr('id', (d, i) ->
      'lr-' + filterKeys[i]
    ).attr('x', 0).attr('y', (d, i) ->
      i * 10
    ).attr('width', 10).attr('height', 10).style('stroke', '#404040').style 'fill', (d, i) ->
      color d
    g.append('text').attr('data-value', 'checked').attr('x', 15).attr('y', (d, i) ->
      i * 10 + 9
    ).attr('font-size', '12px').attr('fill', '#000').html (d, i) ->
      filters[d]
    legend.append('text').attr('x', 15).attr('y', filterKeys.length * 20 + 40).attr('font-size', '12px').attr('fill', '#737373').text 'Click to toggle items'
    return
  return

# ---

