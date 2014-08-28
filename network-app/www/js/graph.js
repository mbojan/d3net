
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
      $("#slider").attr("min", d3properties[0].timeMin);
      $("#slider").attr("max", d3properties[0].timeMax);
      $("#slider").val(Number(d3properties[0].timeMin));
      $("#timeCount").text('Current: ' + d3properties[0].timeMin + ' / ' + d3properties[0].timeMax);

      var nodes = [],
          edges = [],
          radiusArray = [];


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
        if (parseInt(vertex) > acc) 
          return parseInt(vertex); 
        else return acc}, 0) : 0;

      /**
        Zooming the graph
      */
      function zoomGraph() {
        background.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")");
      }

      // remove old svg
      var svg = d3.select(el).select("svg");
      svg.remove();
      
      $(el).html("");
      
      //append a new one
      svg = d3.select(el).append("svg");
      svg.attr("id", "graph")
        .attr("pointer-events", "all")
        .attr("width", width)
        .attr("height", height)
        .attr("viewBox", "0, 0, " + width + ", " + height)
        .attr("preserveAspectRatio", "xMidYMid meet")
        
      var background = svg.append('svg:g').call(d3.behavior.zoom().on("zoom", zoomGraph)).append('g');

      background.append('svg:rect')
        .attr('width', width)
        .attr('height', height)
        .attr('fill', 'white');

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


      if (d3properties[0].directed == 1)
      {
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
      }

      var node = background.selectAll("circle");
      var edge = background.append("svg:g").selectAll("path");

      var animationInterval;
      var time = Number(d3properties[0].timeMin) + 1;

      function runInterval(intervalSeconds) {
        animationInterval = setInterval(function(){
          $("#slider").val(time);
          if (time > d3properties[0].timeMax) 
            return;
          $("#timeCount").text('Current: ' + time + ' / ' + d3properties[0].timeMax);
          updateData(time);
          time++;
        }, intervalSeconds*1000);
      }

      var option;

      $("#interval").change(function() { 
        if (animationInterval === undefined) return;
        clearInterval(animationInterval);
        if (option == 1) runInterval(parseInt($("#interval").val()));
      });

      /**
        Functions for play/stop/replay buttons
      */
      $("#playButton").click(function(){
        option = 1;
        force.start();
        runInterval(parseInt($("#interval").val()));
      })

      $("#pauseButton").click(function(){
        option = 2;
        force.stop();
        clearInterval(animationInterval);
      })

      $("#replayButton").click(function(){
        force.stop();
        clearInterval(animationInterval);
        time = Number(d3properties[0].timeMin) + 1;
        cleanData(Number(d3properties[0].timeMin));
        $("#timeCount").text('Current: ' + d3properties[0].timeMin + ' / ' + d3properties[0].timeMax);
        $("#slider").val(d3properties[0].timeMin);
        force.start();
        runInterval(parseInt($("#interval").val()));
      })

      /**
      Function positioning nodes and edges on every layout change
      */
      function tick() {

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
            //.attr("x", Math.random() * width)
            //.attr("y", Math.random() * height)
            .attr("cx", function(d) { return d.x; })
            .attr("cy", function(d) { return d.y; });
      }

      /**
      Function adds new nodes and edges data to d3 lib
      */
      function redraw() {
        var baseDuration = parseInt($("#interval").val())*125;
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
            .duration(baseDuration)
            .ease("linear")
            .style("fill", function(d) { return d.color;})
            .attr("r", function(d) { return (d.property && maxVertexProperty) ? 
            Math.max(d3properties[0].vertexSizeMin, d3properties[0].vertexSizeMax*(d.property/maxVertexProperty)) : d3properties[0].vertexSizeMin; } );

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

        node.exit()
          .transition()
            .duration(baseDuration)
            .ease("linear")
            .style("fill-opacity", 0.001)
            .remove();

        edge = edge.data(edges);

        edge.enter().append("path")
          .transition()
            .duration(3*baseDuration)
            .style("stroke-width", 3)
            .style("stroke", "red")
          .transition()
            .duration(baseDuration)
            .ease("linear")
            .style("stroke", "black")
            .style("stroke-width", 1);

        if (d3properties[0].directed == 1) 
        {
          svg.selectAll("path").attr("marker-end", "url(#end)")
        }

        edge.exit()
          .transition()
            .duration(baseDuration)
            .ease("linear")
            .style("stroke-opacity", 0.01)
            .remove();
      }

      function updateData(time){
          // add new nodes
        for (var i = 0; i < verticesActivity.length; i++)
          {
            // pass the nodes that are not appearing at this specific moment
            if (verticesActivity[i].onset !== time) continue;

            // add nodes that appear at this moment
            var index = verticesActivity[i]["vertex.id"] - 1 ;
            var radiusProperty = (vertexRadius != 'None' && vertexRadius != null) ? verticesAttributes[vertexRadius][index] : null;
            var colorProperty = (vertexColor != 'None' && vertexColor != null) ? verticesAttributes[vertexColor][index] : 'NA';

            nodes.push({ 
              "name" : vertices[index], 
              "terminus" : verticesActivity[i].terminus,
              "onset" : verticesActivity[i].onset,
              "property" : radiusProperty,
              "color" : projectionColors[colorProperty],
            });
          }
        // remove old nodes
        for (var i = nodes.length - 1; i >= 0; i--)
        {
          if(nodes[i].terminus == time - 1)
            nodes.splice(i,1);
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

      function cleanData(timeReset){
        // remove old edges
        for(var i = edges.length - 1; i >= 0; i--)
        {
          edges.splice(i,1);
        }

        for (var i = 0; i < links.length; i++)
        {
          if (links[i].onset !== timeReset) continue;
          edges.push(links[i]);
        }

        for (var i = nodes.length - 1; i >= 0; i--)
        {
          if (nodes[i].onset !== timeReset) nodes.splice(i,1);
        }

        redraw();
      }

      updateData(Number(d3properties[0].timeMin));

      /**
      Interval for indicating whether shiny is busy
      Shows loading image when R is doing stuff
      */
      setInterval(function(){
        if ($('html').attr('class')=='shiny-busy') {
          setTimeout(function() {
            if ($('html').attr('class')=='shiny-busy') {
              $('div.busy').show();
            }
          }, 1000)
        } else {
          $('div.busy').hide()
        }
      }, 100)
    }

  });

  Shiny.outputBindings.register(networkOutputBinding, 'pawluczuk.networkbinding');