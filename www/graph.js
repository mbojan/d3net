var networkOutputBinding = new Shiny.OutputBinding();

  $.extend(networkOutputBinding, {
    
    find: function(scope) {
      return $(scope).find('.shiny-network-output');
    },
    
    renderValue: function(el, data) {
      //format nodes object
      var nodes = new Array();
      // connections between vertices
      var edges = data.links;
      //if (data == null) console.log("Reading data failed.");
      //console.log("Data length is:" + data.names.length);
      for (var i = 0; i < data.names.length; i++)
      {
        var counter = 0;
        for (var k = 0; k < edges.length; k++)
          {
              if (edges[k].source == i || edges[k].target == i)
                counter++;
          }
        //console.log("Data name of: " + i + " - " + data.names[i]);
        nodes.push({"name": data.names[i], "connCount" : counter});
        //console.log("Idx: " + i + "\tName: " + data.names[i] + "\tConnCount: " + counter );
      }

      var width = 800;
      var height = 600;

      var force = d3.layout.force()
        .nodes(nodes)
        .links(edges)
        .charge(-100)
        .linkDistance(200)
        .size([width, height])
        .start();
      
      //remove the old graph
      var svg = d3.select(el).select("svg");
      svg.remove();
      
      $(el).html("");
      
      //append a new one
      svg = d3.select(el).append("svg");
      
      svg.attr("width", width)
        .attr("height", height);

      var link = svg.selectAll("line.link")
          .data(edges)
          .enter()
          .append("line")
          .attr("class", "link")
          .style("stroke", "#6E6E6E")
          .style("stroke-opacity", "0.5")
          .style("stroke-width", function(d) { return d.weight; });

      var vertexes = svg.selectAll("g")
          .data(nodes);

      var g = vertexes.enter()
          .append("g")
          .attr("class", "graph-node")
          .call(force.drag);

      var circle = g.append("circle")
          .attr("class", "circle")
          .attr("r", function(d) { return (Math.E)^(2*d.connCount); } )
          .attr("fill", "#04B486")
          //.attr("fill-opacity", "0.5")
          .style("stroke", "#fff")
          .style("stroke-width", "1px")
          .call(force.drag); 

      var label = g.append("text")
          .text(function(d) { return d.name; })
          .attr("class", "label")
          //.style("color", "#6E6E6E")
          .style("font-size", function(d) { return Math.max(8, 2 * d.connCount) + "px"; });
      //    .style("display", "none");


      force.on("tick", function() {
            link.attr("x1", function(d) { return d.source.x; })
            .attr("y1", function(d) { return d.source.y; })
            .attr("x2", function(d) { return d.target.x; })
            .attr("y2", function(d) { return d.target.y; });
            
            g.attr("transform", function(d) { return 'translate(' + [d.x, d.y] + ')'; })
        });


      /* hide text, and unhide it + highlight circle on mouseover
      $(".circle").mouseover(function(){
        $(this).attr("fill", "#B1DCFE");
        $(this).parent(".graph-node").children(".label").css("display", "inline");
      });

      $(".circle").mouseout(function(){
        $(this).attr("fill", "steelblue");
        $(this).parent(".graph-node").children(".label").css("display", "none");
      });*/
    }

  });

  Shiny.outputBindings.register(networkOutputBinding, 'pawluczuk.networkbinding');