
var networkOutputBinding = new Shiny.OutputBinding();
       

  $.extend(networkOutputBinding, {

    find: function(scope) {
      return $(scope).find('.shiny-network-output');
    },
    
    renderValue: function(el, data) {
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

      //console.log(verticesAttributes)
      
      
      /**
      Preparation of data sent by R
      */
      colorsArray = new Array();

      for (var i = 0; i < vertices.length; i++)
      {
        value = (vertexColor != 'None' && vertexColor != null) ? verticesAttributes[vertexColor][i] : '';
        if (!colorsArray[value]) 
          {
            var newColor = randomColor({luminosity: 'light'});
            while (colorsArray.indexOf(newColor) != -1)
            {
              newColor = randomColor({luminosity: 'light'});
            }
            colorsArray[value] = newColor;
          }
        property = (vertexRadius != 'None' && vertexRadius != null) ? verticesAttributes[vertexRadius][i] : null;
        nodes.push({"name": vertices[i], "property" : property, "color" : colorsArray[value]});
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

      function update(time) 
      {
        var path = svg.selectAll("path")
          .data(edges);

        path.attr("class", "update")
          .transition()
          .duration(750)
          .attr("x", function(d, i) { return i * 32; });

        path.enter().append("path")
            .attr("class", "enter")


        path.style("stroke", "#6E6E6E")
          .style("stroke-width", 3)
          .attr("stroke-opacity", function(d)
          {
            if (time < d.onset || time > d.terminus)
                {
                  return 0.1;
                }
            return 1;
          })


        var vertexes = svg.selectAll("circle")
          .data(nodes);

        vertexes.attr("class", "update");

        vertexes.enter().append("circle")
          .attr("class", "enter");

        vertexes.data(nodes)
          .attr("r", 10)
          .attr("fill", "red")
          .style("stroke", "#fff")
          .call(force.drag);

        force.on("tick", function() {
          path.attr("d", function(d) {
                  var dr = 0;
              return "M" + 
                  d.source.x + "," + 
                  d.source.y + "A" + 
                  dr + "," + dr + " 0 0,1 " + 
                  d.target.x + "," + 
                  d.target.y;
          })
          vertexes.attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; })
        });
        
        path.exit().remove();
        vertexes.exit().remove();
      }

      update(time);
      var time = 0;
      setInterval(function() {
        if (graphType == 'networkDynamic')
        {
          time = (time+1)%d3properties[0].timeMax;
        }
        update(time);
      }, 1500);


      /** 
      Adding vertices on the graph
      g - vertex contsiting of:
        |____circle
        |____label (showing on mouseover)
      */


    }

  });

  Shiny.outputBindings.register(networkOutputBinding, 'pawluczuk.networkbinding');