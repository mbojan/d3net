
var networkOutputBinding = new Shiny.OutputBinding();
  $.extend(networkOutputBinding, {

    find: function(scope) {
      return $(scope).find('.shiny-network-output');
    },
    
    renderValue: function(el, data) {
      $("#color").colorpicker();

      /**
      Used variables 
      */
      var width = 7/12* $(window).width();
      var height = 0.75 * $(window).height();
      var maxVertexProperty = 0.0;
      var maxEdgeProperty = 0.0;
      var nodes = new Array();
      var edges = data.links;
      var vertices = data.vertices;
      var d3properties = data.d3;
      var tooltipInfo = data.tooltipInfo;
      var verticesAttributes = data.verticesAttributes;
      var vertexRadius = data.vertexRadius;
      var vertexColor = data.vertexColor;
      var graphType = data.graphType;
      var color = d3properties[0].color;
      var minColor = 'lightyellow';
      var colorScalePicker = d3.scale.category10().domain(d3.range(0,10));
      var scale = d3.scale.linear().range([colorScalePicker(color), minColor]);
      
      var stringsForColoring = [];
      var projectionColors = {};

      for (var i = 0; i < vertices.length; i++)
      {
        value = (vertexColor != 'None' && vertexColor != null) ? verticesAttributes[vertexColor][i] : 'NA';
        stringsForColoring.push(value)
      }

      // leave only unique elements
      stringsForColoring = stringsForColoring.filter(function(elem, pos, self) {
          return self.indexOf(elem) == pos;
      })
      for (var stringId in stringsForColoring)
      {
        if (!projectionColors[stringsForColoring[stringId]])
          projectionColors[stringsForColoring[stringId]] = scale(stringId/stringsForColoring.length);
      }
      for (var i = 0; i < vertices.length; i++)
      {
        value = (vertexColor != 'None' && vertexColor != null) ? verticesAttributes[vertexColor][i] : 'NA';
        property = (vertexRadius != 'None' && vertexRadius != null) ? verticesAttributes[vertexRadius][i] : null;
        nodes.push({"name": vertices[i], "property" : property, "color" : projectionColors[value]});
      }

      /**
      Maximum and minimum vertices values - for normalization
      */
      maxVertexProperty = nodes.reduce(function(acc, vertex) { 
        if (Number(vertex.property) > acc) 
          return Number(vertex.property); 
        else return acc}, 0);

      maxEdgeProperty = edges.reduce(function(acc, edge) { 
        if (Number(edge.property) > acc) 
          return Number(edge.property); 
        else return acc;  }, 0)

      /**
      Creating d3 graph
      */
      var force = d3.layout.force()
        .nodes(nodes)
        .links(edges)
        .charge(d3properties[0].charge)
        .linkDistance(d3properties[0].linkDistance)
        .linkStrength(d3properties[0].linkStrength)
        .size([width, height])
        .start();
      
      //remove the old graph
      var svg = d3.select(el).select("svg");
      svg.remove();
      
      $(el).html("");
      
      //append a new one
      svg = d3.select(el).append("svg");

      /**
      Add svg properties to become responsive (adjusting width and height)
      */
      svg.attr("id", "graph")
        .attr("width", width)
        .attr("height", height)
        .attr("viewBox", "0, 0, " + width + ", " + height)
        .attr("preserveAspectRatio", "xMidYMid meet");

      var graph = $("#graph"),
          aspect = graph.width() / graph.height(),
          container = graph.parent();

      $(window).on("resize", function() {
          var targetWidth = container.width();
          graph.attr("width", targetWidth);
          graph.attr("height", Math.round(targetWidth / aspect));
      }).trigger("resize");

      var markerSize = 3;

      svg.append("svg:defs").selectAll("marker")
        .data(["end"])      // Different link/path types can be defined here
      .enter().append("svg:marker")    // This section adds in the arrows
        .attr("id", String)
        .attr("viewBox", "0 -5 10 10")
        .attr("refX", function(d) { return 3*markerSize; })
        .attr("markerWidth", markerSize)
        .attr("markerHeight", markerSize)
        .attr("orient", "auto")
        .style("fill", "#6E6E6E")
      .append("svg:path")
        .attr("d", "M0,-5L10,0L0,5");

      
      // add the links and the arrows
      var path = svg.selectAll("path")
          .data(edges)
        .enter().append("svg:path")
          .attr("class", "link")
          .style("stroke", "#6E6E6E")
          .style("stroke-opacity", function(d) { return (d.property) ? Math.max(0.3,(d.property/maxEdgeProperty)) : 0.5; })
          .style("stroke-width", function(d) { return (d.property) ? Math.max(3,10*(d.property/maxEdgeProperty)) : 3; })
          .attr("marker-end", "url(#end)");

      if (d3properties[0].directed)
      {
        svg.selectAll("path").attr("marker-end", "url(#end)")
      }
      
      /** 
      Adding vertices on the graph
      g - vertex contsiting of:
        |____circle
        |____label (showing on mouseover)
      */
      var vertexes = svg.selectAll("g")
          .data(nodes);

      var g = vertexes.enter()
          .append("g")
          .attr("class", "graph-node")
          .call(force.drag);

      var circle = g.append("circle")
          .attr("class", "circle")
          .attr("r", function(d) { return (d.property && maxVertexProperty) ? 
            Math.max(d3properties[0].vertexSizeMin, d3properties[0].vertexSizeMax*(d.property/maxVertexProperty)) : d3properties[0].vertexSizeMin; } )
          .attr("fill", function(d) {
            return d.color;
          })
          .style("stroke", "#fff")
          .style("stroke-width", "1px");

      /**
      Creating tooltip
      */
      $('circle').tipsy({ 
        gravity: 'w', 
        html: true, 
        title: function() {
        var d = this.__data__;
            var properties = '';
            
            if (vertexColor != 'None' && vertexColor != null)
            {
              colorLegend = (verticesAttributes[vertexColor][d.index] != null) ? verticesAttributes[vertexColor][d.index] : 'NA';
              properties += '<span style="text-align: left; font-size: 5em; color: ' + d.color + '">' + '&#9679' + '</span><p><b>' + colorLegend + '</b></p>';
            }             

            if (tooltipInfo != null)
            {
              properties += '<table>';

              for (i = 0; i < tooltipInfo.length; i++)
              {
                properties += '<tr><td style="text-align: left">' + tooltipInfo[i].toUpperCase() + '</td><td style="text-align: right">' + verticesAttributes[tooltipInfo[i]][d.index] + '</td></tr>';
              }
              properties += '</table>';
            }
            
            return '<span class="tipsy-title">' + d.name + '</span><br/>' + "\n" + properties;
        }
      });

      var radiusArray = new Array();
      d3.selectAll("circle").each( function(d, i){
                      radiusArray[this.__data__.index] = d3.select(this).attr("r");
                    });

      force.on("tick", function() {
        path.attr("d", function(d) {
                    var r = radiusArray[d.target.index];
                    var dr = 0;
                    var temp  = Math.sqrt(r * r * (d.source.y - d.target.y) * (d.source.y - d.target.y) / 
                        ((d.source.x - d.target.x)*(d.source.x - d.target.x) + (d.source.y - d.target.y)*(d.source.y - d.target.y)));

                    var yr, xr;
                    if (d.source.y < d.target.y) 
                      {
                        yr = d.target.y - temp;
                        xr = d.target.x - temp*(d.source.x - d.target.x)/(d.source.y - d.target.y);
                      }
                      else
                      {
                        yr = d.target.y + temp;
                        xr = d.target.x + temp*(d.source.x - d.target.x)/(d.source.y - d.target.y);
                      }
                    
                return "M" + 
                    d.source.x + "," + 
                    d.source.y + "A" + 
                    dr + "," + dr + " 0 0,1 " + 
                    xr + "," + 
                    yr;
            });

        circle
          .attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });        
      });
    
      /**
      Interval for indicating whether shiny is busy
      Shows loading image when R is doing stuff
      */
      setInterval(function(){
        if ($('html').attr('class')=='shiny-busy') {
          setTimeout(function() {
            if ($('html').attr('class')=='shiny-busy') {
              $('div.busy').show()
            }
          }, 1000)
        } else {
          $('div.busy').hide()
        }
      }, 100)

    }

  });

  Shiny.outputBindings.register(networkOutputBinding, 'pawluczuk.networkbinding');