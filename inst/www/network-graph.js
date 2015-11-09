
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
      var links = formatLinks(jQuery.extend(true, [], data.links));
      var vertices = data.vertices;
      var d3properties = data.d3;
      var tooltipInfo = data.tooltipInfo;
      var verticesAttributes = data.verticesAttributes;
      var vertexRadius = data.vertexRadius;
      var vertexColor = data.vertexColor;
      var graphType = data.graphType;
      var verticesActivity = formatVerticesActivity(data.verticesActivity);
      var color = d3properties.color;
      var width = 7/12* $(window).width();
      var height = 0.75 * $(window).height();

      var minColor = 'lightyellow';
      var colorScalePicker = d3.scale.category10().domain(d3.range(0,10));
      var colorScale = d3.scale.linear().range([colorScalePicker(color), minColor]);

      var playButtonHtml = '<button type="button" class="btn btn-default" id="playButton">' + 'Play' + '</button>';
      var pauseButtonHtml = '<button type="button" class="btn btn-default" id="pauseButton">' + 'Pause' + '</button>';
      var replayButtonHtml = '<button type="button" class="btn btn-default" id="replayButton">' + 'Replay' + '</button>';
      var zoomButtonHtml = '<button type="button" class="btn btn-default" id="zoomButton">Zooming</button>';
      $("#player").html(playButtonHtml + pauseButtonHtml + replayButtonHtml + zoomButtonHtml);
      $("#slider").attr("min", d3properties.timeMin);
      $("#slider").attr("max", d3properties.timeMax);
      $("#slider").val(Number(d3properties.timeMin));
      $("#timeCount").html('<b>Current</b> ' + d3properties.timeMin + ' / ' + d3properties.timeMax);
      $("#timeInfo").html('<b>Time range</b> ' + d3properties.timeMin + ' - ' + d3properties.timeMax);
      $("#logo").removeAttr("style");

      var nodes = [],
          edges = [],
          radiusArray = [];
      var currentInterval = parseInt($("#interval").val());

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

      
      // formatting R data
      function formatVerticesActivity (array) {
      	var verticesActivity = [];
      	// properties order: vertex.id onset terminus
      	array.forEach(function(element) {
      		verticesActivity.push({
      			"vertex.id" : element[0],
      			"onset" : element[1],
      			"terminus" : element[2]
      		});
      	});
      	return verticesActivity;
      }

      function formatLinks (array) {
      	var links = [];
      	// propeties order: onset terminus source target property
      	array.forEach(function(element) {
      		links.push({
      			onset : element[0],
      			terminus : element[1],
      			source : element[2],
      			target : element[3],
      			property : element[4]
      		});
      	});
      	return links;
      }

      /**
        Zooming the graph
      */

      function zoomGraph() {
        if (currentTranslation != null && currentScale != null)
        {
          zoom.translate(currentTranslation);
          zoom.scale(currentScale)
          currentTranslation = null;
          currentScale = null;
        }
        background.attr("transform", "translate(" +  zoom.translate() + ")scale(" + zoom.scale() + ")");
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
        .attr("preserveAspectRatio", "xMidYMid meet");

      var x = d3.scale.linear()
          .domain([0, width])
          .range([0, width]);

      var y = d3.scale.linear()
          .domain([0, height])
          .range([height, 0]);
        
      var background = svg.append('svg:g');

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
          .charge(d3properties.charge)
          .linkDistance(d3properties.linkDistance)
          .linkStrength(d3properties.linkStrength)
          .size([width, height])
          .on("tick", tick);


      if (d3properties.directed == 1)
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
      var time = Number(d3properties.timeMin) + 1;

      function runInterval(intervalSeconds) {
        animationInterval = setInterval(function(){
          $("#slider").val(time);
          if (time > d3properties.timeMax)
            { 
              $("#playButton").removeClass('active');
              option = undefined;
              clearInterval(animationInterval);
              return;
            }
          $("#timeCount").html('<b>Current</b> ' + time + ' / ' + d3properties.timeMax);
          updateData(time);
          time++;
        }, intervalSeconds*1000);
      }

      var currentTranslation = null;
      var currentScale = null;
      $("#zoomButton").click(function(){
        if ($(this).hasClass('active'))
        {
          $(this).removeClass('active');
          if (currentTranslation == null) currentTranslation = zoom.translate();
          if (currentScale == null) currentScale = zoom.scale();
          background.call(zoom = d3.behavior.zoom().on("zoom", null));
          node.call(force.drag);
        }
        else
        {
          $(this).addClass('active');
          background.call(zoom = d3.behavior.zoom().on("zoom", zoomGraph));
          node.on('mousedown.drag', null);
        }
      })

      function reset(){
        if ($(this).attr("id") === "interval")
        {
          currentInterval = parseInt($("#interval").val());
          if (animationInterval === undefined) return;
          clearInterval(animationInterval);
          if (option == 1) runInterval(currentInterval);
        }
        else
        {
          clearInterval(animationInterval);
          time = Number(d3properties.timeMin) + 1;
          $("#playButton").removeClass('active');
          $("#pauseButton").removeClass('active');
          $("#timeCount").html('<b>Current</b> ' + d3properties.timeMin + ' / ' + d3properties.timeMax);
          $("#slider").val(d3properties.timeMin);
        }

        if ($(this).attr("id") === "replayButton")
        {
          cleanData(Number(d3properties.timeMin));
        }
      }

      var option;

      /**
        Functions for play/stop/replay buttons
      */
      $("#playButton").click(function(){
        option = 1;
        $(this).addClass('active');
        $("#pauseButton").removeClass('active');
        force.start();
        runInterval(currentInterval);
      })

      $("#pauseButton").click(function(){
        option = 2;
        $(this).addClass('active');
        $("#playButton").removeClass('active');

        force.stop();
        clearInterval(animationInterval);
      })
      $( document ).off('keypress').keypress(function(event){
        if ( event.keyCode === 32 )
        {
          if (option === 1)
          {
            option = 2;
            $("#pauseButton").addClass('active');
            $("#playButton").removeClass('active');

            force.stop();
            clearInterval(animationInterval);
          }
          else if (option === 2)
          {
            option = 1;
            $("#playButton").addClass('active');
            $("#pauseButton").removeClass('active');
            force.start();
            runInterval(currentInterval);
          }
        }
      });

      $("#replayButton").click(reset);
      $("#layoutd3").find("input").change(reset);
      $("#layoutR").find("input").change(reset);

      var timeout;
      $("#slider").change(function() {
        var userTime = Number($(this).val());
        clearInterval(animationInterval);
        if (timeout) clearInterval(timeout);
        timeout = setTimeout(function() {
          cleanData(userTime);
        }, 150);
        time = userTime + 1;
        // if the loop was on, continue
        if (option == 1) runInterval(currentInterval);
        $("#timeCount").html('<b>Current</b> ' + userTime + ' / ' + d3properties.timeMax);
      })

      node.each( function(d, i){
        if (this !== undefined)
            radiusArray[this.__data__.index] = d3.select(this).attr("r");
          });

      /**
      Function positioning nodes and edges on every layout change
      */
      function tick() {

        node.each( function(d, i){
            radiusArray[this.__data__.index] = d3.select(this).attr("r");
          });

        edge
          .attr("d", function(d) {
            // if there's a loop
            // NEEDS FIX - RADIUS CALCULATIONS
            if (d.source.x == d.target.x && d.source.y == d.target.y) 
              return "M"  + 
                  d.source.x + "," + 
                  d.source.y + "A" + 
                  10 + "," + 10 + " 0 0,1 " + 
                  d.source.x + "," + 
                  d.source.y;
            var r = (radiusArray[d.target.index]) ? radiusArray[d.target.index] : d3properties.vertexSizeMin;
            var r2 = (radiusArray[d.source.index]) ? radiusArray[d.source.index] : d3properties.vertexSizeMin;
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
      Function passes new nodes and edges data to d3 lib
      */
      function redraw() {
        var baseDuration = currentInterval*125;
        force.start();
        node = node.data(nodes);

        node.enter().append("circle")
            .attr("class", "node")
            .attr("cx", function(d) { return d.x; })
            .attr("cy", function(d) { return d.y; })
            .attr("r", d3properties.vertexSizeMax)
            .style("fill", minColor)
            .style("stroke", "black")
          .transition()
            .duration(baseDuration)
            .ease("linear")
            .style("fill", function(d) { return d.color;})
            .attr("r", function(d) { 
            	return (d.property && maxVertexProperty) ? 
	            	Math.max(d3properties.vertexSizeMin, d3properties.vertexSizeMax*(d.property/maxVertexProperty)) 
	            	: d3properties.vertexSizeMin; 
	           } );

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

        if (d3properties.directed == 1) 
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

      function updateData(time) {
        // add new nodes
        for (var i = 0; i < verticesActivity.length; i++)
          {
            if (Number(verticesActivity[i].onset) !== time) continue;
            // add nodes that appear at this moment
            var index = verticesActivity[i]["vertex.id"] - 1 ;
            var radiusProperty = (vertexRadius != 'None' && vertexRadius != null) ? verticesAttributes[vertexRadius][index] : null;
            var colorProperty = (vertexColor != 'None' && vertexColor != null) ? verticesAttributes[vertexColor][index] : 'NA';

            nodes.push({ 
              "name" : vertices[index], 
              "terminus" : Number(verticesActivity[i].terminus),
              "onset" : Number(verticesActivity[i].onset),
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
          if (Number(links[i].onset) != time) continue;
          var elToPush = links[i];
          elToPush.onset = Number(elToPush.onset);
          elToPush.terminus = Number(elToPush.terminus);
          elToPush.source = Number(elToPush.source);
          elToPush.target = Number(elToPush.target);
          // if the nodes for this edge do not exist
          if (nodes[elToPush.source] === undefined || nodes[elToPush.target] === undefined) continue;
          // if the nodes do not exist at this timestamp
          if (nodes[elToPush.source].onset > time || nodes[elToPush.target].onset > time) continue;
          if (nodes[elToPush.source].terminus < time || nodes[elToPush.target].terminus < time) continue;
          edges.push(elToPush);
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
        links = jQuery.extend(true, [], data.links);
        edges.splice(0, edges.length);
        nodes.splice(0, nodes.length);
        for (var i = 0; i < verticesActivity.length; i++)
        {
          if (Number(verticesActivity[i].onset) > timeReset || Number(verticesActivity[i].terminus) < timeReset) continue;
            // add nodes that appear at this moment
            var index = verticesActivity[i]["vertex.id"] - 1 ;
            var radiusProperty = (vertexRadius != 'None' && vertexRadius != null) ? verticesAttributes[vertexRadius][index] : null;
            var colorProperty = (vertexColor != 'None' && vertexColor != null) ? verticesAttributes[vertexColor][index] : 'NA';

            nodes.push({ 
              "name" : vertices[index], 
              "terminus" : Number(verticesActivity[i].terminus),
              "onset" : Number(verticesActivity[i].onset),
              "property" : radiusProperty,
              "color" : projectionColors[colorProperty],
            });
        }

        // add new edges
        for (var i = 0; i < links.length; i++)
        {
          if (Number(links[i].onset) > timeReset || Number(links[i].terminus) < timeReset) continue;
          var elToPush = links[i];
          elToPush.onset = Number(elToPush.onset);
          elToPush.terminus = Number(elToPush.terminus);
          elToPush.source = Number(elToPush.source);
          elToPush.target = Number(elToPush.target);
          // if the nodes for this edge do not exist
          if (nodes[elToPush.source] === undefined || nodes[elToPush.target] === undefined) continue;
          // if the nodes do not exist at this timestamp
          if (nodes[elToPush.source].onset > timeReset || nodes[elToPush.target].onset > timeReset) continue;
          if (nodes[elToPush.source].terminus < timeReset || nodes[elToPush.target].terminus < timeReset) continue;
          edges.push(elToPush);
        }
        redraw();
      }

      updateData(Number(d3properties.timeMin));

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