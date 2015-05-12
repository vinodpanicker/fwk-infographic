require.config({
  baseDir: 'app',
  shim : {
    bootstrap : {
      deps : ['jquery']
    }
  },
  paths: {
    jquery: 'vendor/jquery/dist/jquery',
    bootstrap: 'vendor/bootstrap/dist/js/bootstrap',
    handlebars: 'vendor/handlebars/handlebars',
    d3: 'vendor/d3/d3'
  }
});

require(['jquery', 'bootstrap', './data', 'handlebars', 'd3'], function($, bootstrap, frameworks, Handlebars, d3) {
  var m = {};
  // get unique elements in order
  var order = frameworks.map(function(r) {
    return r[0]
  }).filter(function(a,i,all) {
    return i == 0 ? true : all[i-1] !== a;
  });

  frameworks.forEach(function(row) {
    var a = m[row[0]] || [];
    a.push({name: row[1], link: row[2], src: row[3]});
    m[row[0]] = a;
  });
  var page = $('#page');
  var template = Handlebars.compile($('#grp-tmpl').html());
  order.forEach(function(grp) {
    page.append(template({ groupName: grp.replace(/-/g, ' '), frameworks: m[grp] }));
  });

  var width = 500, height = 500;
  var svg = d3.select('#right').append('svg')
      .attr('width', width)
      .attr('height', height)
      .append('rect')
      .attr("x",0)
      .attr("y",0)
      .attr("width",width)
      .attr("height",height)
      .style("fill","#e5f5f9");
})
