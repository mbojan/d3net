
var networkOutputBinding = new Shiny.OutputBinding();
       

  $.extend(networkOutputBinding, {

    find: function(scope) {
      return $(scope).find('.shiny-network-output');
    },
    
    renderValue: function(el, data) {
      /**
      Used variables 
      */
      var maxVertexProperty = 0.0;
      var maxEdgeProperty = 0.0;
      var links = data.links;
      var vertices = data.vertices;
      var d3properties = data.d3;
      var tooltipInfo = data.tooltipInfo;
      var verticesAttributes = data.verticesAttributes;
      var vertexRadius = data.vertexRadius;
      var vertexColor = data.vertexColor;
      var graphType = data.graphType;
      var verticesActivity = data.verticesActivity;
      var color = d3properties[0].color;
      var width = 7/12* $(window).width();
      var height = 0.75 * $(window).height();

      var minColor = 'lightyellow';
      var colorScalePicker = d3.scale.category10().domain(d3.range(0,10));
      var colorScale = d3.scale.linear().range([colorScalePicker(color), minColor]);

      var playButtonHtml = '<button type="button" class="btn btn-default" id="playButton">' + '<i class="icon-play"></i>' + '</button>'
      var pauseButtonHtml = '<button type="button" class="btn btn-default" id="pauseButton">' + '<i class="icon-pause"></i>' + '</button>'
      var replayButtonHtml = '<button type="button" class="btn btn-default" id="replayButton">' + '<i class="icon-repeat"></i>' + '</button>'
      $("#player").html(playButtonHtml + pauseButtonHtml + replayButtonHtml);
      $("#colorScaleDiv").find(".selectize-dropdown-content > div").each(function() { 
        console.log("a");
      })
      
      var nodes = [],
          edges = [],
          radiusArray = [];

      var animationInterval;
      var time = 1;

      function runInterval() {
        animationInterval = setInterval(function(){
          if (time > d3properties[0].timeMax) return;
          updateData(time);
          time++;
        }, 4000);
      }

      $("#playButton").click(function(){
        console.log("play");
        force.start();
        runInterval();
      })

      $("#pauseButton").click(function(){
        console.log("pause");
        force.stop();
        clearInterval(animationInterval);
      })

      $("#replayButton").click(function(){
        console.log("resume");
        clearInterval(animationInterval);
        edges = [];
        nodes = [];
        updateData(0);
        time = 1;
      })

      // color map for nodes
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
          projectionColors[stringsForColoring[stringId]] = colorScale(stringId/stringsForColoring.length);
      }

      // for normalization: maximum property value that radius reflects (if none, then 0)  
      maxVertexProperty = (verticesAttributes[vertexRadius]) ? verticesAttributes[vertexRadius].reduce(function(acc, vertex) { 
        if (vertex > acc) 
          return vertex; 
        else return acc}, 0) : 0;

      // remove old svg
      var svg = d3.select(el).select("svg");
      svg.remove();
      
      $(el).html("");
      
      //append a new one
      svg = d3.select(el).append("svg");
      svg.attr("id", "graph")
        .attr("width", width)
        .attr("height", height)
        .attr("viewBox", "0, 0, " + width + ", " + height)
        .attr("preserveAspectRatio", "xMidYMid meet");

      var graph = $("#graph"),
          aspect = graph.width() / graph.height(),
          container = graph.parent();

      // automatic svg resize
      $(window).on("resize", function() {
          var targetWidth = container.width();
          graph.attr("width", targetWidth);
          graph.attr("height", Math.round(targetWidth / aspect));
      }).trigger("resize");

      var force = d3.layout.force()
          .nodes(nodes)
          .links(edges)
          .charge(d3properties[0].charge)
          .linkDistance(d3properties[0].linkDistance)
          .linkStrength(d3properties[0].linkStrength)
          .size([width, height])
          .on("tick", tick);

      var markerSize = 7;

      svg.append("svg:defs").selectAll("marker")
        .data(["end"])      // Different link/path types can be defined here
      .enter().append("svg:marker")    // This section adds in the arrows
        .attr("id", String)
        .attr("viewBox", "0 -5 10 10")
        .attr("refX", function(d) { return markerSize; })
        .attr("markerWidth", markerSize)
        .attr("markerHeight", markerSize)
        .attr("orient", "auto")
      .append("svg:path")
        .attr("d", "M0,-5L10,0L0,5");

      var node = svg.selectAll("circle");
      var edge = svg.append("svg:g").selectAll("path");

      function tick(e) {
        node.each( function(d, i){
            radiusArray[this.__data__.index] = d3.select(this).attr("r");
          });

        edge
          .attr("d", function(d) {
            var r = radiusArray[d.target.index];
            var r2 = radiusArray[d.source.index];
                    var dr = 0;
                    var temp  = Math.sqrt(r * r * (d.source.y - d.target.y) * (d.source.y - d.target.y) / 
                        ((d.source.x - d.target.x)*(d.source.x - d.target.x) + (d.source.y - d.target.y)*(d.source.y - d.target.y)));
                    var temp2 = Math.sqrt(r2 * r2 * (d.target.y - d.source.y) * (d.target.y - d.source.y) / 
                        ((d.target.x - d.source.x)*(d.target.x - d.source.x) + (d.target.y - d.source.y)*(d.target.y - d.source.y)));

                    var yr, xr;
                    if (d.source.y < d.target.y) 
                      {
                        yr = d.target.y - temp;
                        xr = d.target.x - temp*(d.source.x - d.target.x)/(d.source.y - d.target.y);

                        ys = d.source.y + temp2;
                        xs = d.source.x + temp2*(d.target.x - d.source.x)/(d.target.y - d.source.y);
                      }
                      else
                      {
                        yr = d.target.y + temp;
                        xr = d.target.x + temp*(d.source.x - d.target.x)/(d.source.y - d.target.y);

                        ys = d.source.y - temp2;
                        xs = d.source.x - temp2*(d.target.x - d.source.x)/(d.target.y - d.source.y);
                      }
                    
                return "M" + 
                    xs + "," + 
                    ys + "A" + 
                    dr + "," + dr + " 0 0,1 " + 
                    xr + "," + 
                    yr;
          });

        node
            .attr("cx", function(d) { return d.x; })
            .attr("cy", function(d) { return d.y; });
      }

      function redraw() {
        force.start();

        node = node.data(nodes);

        node.enter().append("circle")
            .attr("class", "node")
            .attr("cx", function(d) { return d.x; })
            .attr("cy", function(d) { return d.y; })
            .attr("r", d3properties[0].vertexSizeMax)
            .style("fill", minColor)
            .style("stroke", "black")
          .transition()
            .duration(1000)
            .ease("linear")
            .style("fill", function(d) { return d.color;})
            .attr("r", function(d) { return (d.property && maxVertexProperty) ? 
            Math.max(d3properties[0].vertexSizeMin, d3properties[0].vertexSizeMax*(d.property/maxVertexProperty)) : d3properties[0].vertexSizeMin; } )

        node.call(force.drag);

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

        node.exit().transition()
          .duration(500)
          .ease("linear")
          .style("fill-opacity", 0.001)
          .remove();

        edge = edge.data(edges);

        edge.enter().append("path")
          .attr("marker-end", "url(#end)")
          .style("stroke", "black")
          .transition()
            .duration(500)
            .style("stroke-width", 3)
          .transition()
            .duration(1500)
            .ease("linear")
            .style("stroke-width", 1)
            

        edge.exit().transition()
          .duration(750)
          .ease("linear")
          .style("stroke-opacity", 0.001)
          .remove();
      }

      function updateData(time)
      {
          // add new nodes
        for (var i = 0; i < verticesActivity.length; i++)
          {
            // pass the nodes that are not appearing at this specific moment
            if (verticesActivity[i].onset !== time) 
              continue;

            // add nodes that appear at this moment
            var index = verticesActivity[i]["vertex.id"] - 1 ;
            var radiusProperty = (vertexRadius != 'None' && vertexRadius != null) ? verticesAttributes[vertexRadius][index] : null;
            var colorProperty = (vertexColor != 'None' && vertexColor != null) ? verticesAttributes[vertexColor][index] : 'NA';

            nodes.push({ "name": vertices[index], 
              "terminus" : verticesActivity[i].terminus,
              "property" : radiusProperty,
              "color" : projectionColors[colorProperty]
            });
          }
        // remove old nodes
        for (var i = nodes.length - 1; i >= 0; i--)
        {
          if(nodes[i].terminus == time - 1){
            nodes.splice(i,1);
          }
        }
        // add new edges
        for (var i = 0; i < links.length; i++)
        {
          if (links[i].onset != time) continue;
          edges.push(links[i]); 
        }

        // remove old edges
        for(var i = edges.length - 1; i >= 0; i--)
        {
          if(edges[i].terminus == time - 1){
            edges.splice(i,1);
          }
        }

        redraw();
      }

      updateData(0);

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