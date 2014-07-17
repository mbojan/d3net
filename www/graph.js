
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
      var verticesTooltip = data.verticesTooltip;

      /**
      Preparation of data sent by R
      */
      for (var i = 0; i < vertices.length; i++)
      {
        nodes.push({"name": vertices[i].vertex, "property" : vertices[i].property});
      }
      maxVertexProperty = vertices.reduce(function(acc, vertex) { 
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
        .charge(-300)
        .linkDistance(150)
        .gravity(0.15)
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

      /**
      Adding edges between vertices on the graph
      */
      var link = svg.selectAll("line.link")
          .data(edges)
          .enter()
          .append("line")
          .attr("class", "link")
          .style("stroke", "#6E6E6E")
          .style("stroke-opacity", function(d) { return (d.property) ? Math.max(0.2,(d.property/maxEdgeProperty)) : 0.5; })
          .style("stroke-width", function(d) { return (d.property) ? Math.max(0.8,7*(d.property/maxEdgeProperty)) : 2; });
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
          .attr("r", function(d) { return (d.property) ? Math.max(5,30*(d.property/maxVertexProperty)) : 7; } )
          //.attr("fill-opacity", function(d) { return 0.5 + 0.5*d.property/maxVertexProperty; })
          .attr("fill", "#04B486")
          .style("stroke", "#fff")
          .style("stroke-width", "1px");

      /*var label = g.append("text")
         .text(function(d) { 
            obj = verticesTooltip[d.index];
            var properties = '';
            for (property in obj) {
              properties += '\n' + property + '\t' + obj[property];
            }
            return d.name + properties; }) 
          .attr("class", "label")
          .style("font-size", function(d) { return (d.property) ? Math.max(0.8,2*(d.property/maxVertexProperty)) + "em" : "0.8 em"; })
          .style("display", "none");*/

      /**
      Creating tooltip
      */
      $('g').tipsy({ 
        gravity: 'w', 
        html: true, 
        title: function() {
          var d = this.__data__;
          obj = verticesTooltip[d.index];
            var properties = '';
            for (property in obj) {
              properties += '\n' + property + '\t' + obj[property];
            }
            return d.name + "\n" + properties;
        }
      });

      force.on("tick", function() {
            link.attr("x1", function(d) { return d.source.x; })
            .attr("y1", function(d) { return d.source.y; })
            .attr("x2", function(d) { return d.target.x; })
            .attr("y2", function(d) { return d.target.y; });
            
            g.attr("transform", function(d) { return 'translate(' + [d.x, d.y] + ')'; })
        });

      $(".circle").mouseover(function(){
        $(this).parent(".graph-node").children(".label").css("display", "inline");
      });

      $(".circle").mouseout(function(){
        $(this).parent(".graph-node").children(".label").css("display", "none");
      });
    }

  });

  Shiny.outputBindings.register(networkOutputBinding, 'pawluczuk.networkbinding');