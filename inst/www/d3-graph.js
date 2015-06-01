(function (window) {
	'use strict';

	var d3graph = { name: "graph with force layout based on d3.js" };

	d3graph.generate = function(el, properties, nodes, edges, verticesAttributes, tooltipInfo) {
		var markerSize = properties.markerSize || 3;
		var currentTranslation = null;
	  	var currentScale = null;
	  	var zoom;

		var force = d3.layout.force()
			.nodes(nodes)
			.links(edges)
			.charge(properties.charge || 200)
			.linkDistance(properties.linkDistance || 50)
			.linkStrength(properties.linkStrength || 0.5)
			.size([properties.width || 400 , properties.height || 400])
			.start();

		var svg = d3.select(el).select("svg");
		svg.remove();
	  
		$(el).html("");
	  
		svg = d3.select(el).append("svg");

		/**
		Add svg properties to become responsive (adjusting width and height)
		*/
		svg.attr("id", "graph")
			.attr("pointer-events", "all")
			.attr("width", properties.width)
			.attr("height", properties.height)
			.attr("viewBox", "0, 0, " + properties.width + ", " + properties.height)
			.attr("preserveAspectRatio", "xMidYMid meet");

		var background = svg.append('svg:g');

		background.append('svg:rect')
			.attr('width', properties.width)
			.attr('height', properties.height)
			.attr('fill', 'white');

		var graph = $("#graph");
		var aspect = graph.width() / graph.height();
		var container = graph.parent();

		$(window).on("resize", function() {
			var targetWidth = container.width();
			graph.attr("width", targetWidth);
			graph.attr("height", Math.round(targetWidth / aspect));
		}).trigger("resize");

		  /**
			Zooming the graph
		  */
	  	function zoomGraph() {
			if (currentTranslation !== null && currentScale !== null) {
			  	zoom.translate(currentTranslation);
			  	zoom.scale(currentScale);
			  	currentTranslation = null;
			  	currentScale = null;
			}
			background.attr('transform', 'translate(' + d3.event.translate + ')' +
					' scale(' + d3.event.scale + ')');
	  	}


	  	$("#zoomButton").unbind('click').bind('click',function() {
			if ($(this).hasClass('active')) {
				$(this).removeClass('active');
				if (currentTranslation === null) 
					currentTranslation = zoom.translate();
				if (currentScale === null) 
					currentScale = zoom.scale();
				background.call(zoom.on('zoom', null));
				g.call(force.drag);
			}
			else {
			  	$(this).addClass('active');
			  	background.call(zoom = d3.behavior.zoom().on('zoom', zoomGraph));
			  	g.on('mousedown.drag', null);
			}
	  	});

	  	svg.append("svg:defs").selectAll("marker")
			.data(["end"])      
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
	  	var path = background.selectAll("path")
			.data(edges)
		.enter().append("svg:path")
			.attr("class", "link")
			.style("stroke", "#6E6E6E")
			.style("stroke-opacity", function(d) { return strokeOpacity(d, properties); })
			.style("stroke-width", function(d) { return strokeWidth(d, properties); })
			.attr("marker-end", "url(#end)");

	  if (properties.directed)
			svg.selectAll("path").attr("marker-end", "url(#end)");
	  
	  /** 
	  Adding vertices on the graph
	  g - vertex contsiting of:
		|____circle
		|____label (showing on mouseover)
	  */
	  var vertexes = background.selectAll("g")
		  .data(nodes);

	  var g = vertexes.enter()
		  .append("g")
		  .attr("class", "graph-node")
		  .call(force.drag);

	  var circle = g.append("circle")
		  .attr("class", "circle")
		  .attr("r", function(d) { return circleRadius(d, properties); })
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
				return formatTooltip(d, verticesAttributes, properties, tooltipInfo);
			}
		});

		var radiusArray = [];
		d3.selectAll("circle").each( function(d, i){
		  radiusArray[this.__data__.index] = d3.select(this).attr("r");
		});

		force.on("tick", function() {
			path
				.attr("d", function(d) { return getPathTick(d, radiusArray); });
			circle
				.attr("transform", getCircleTransformTick);        
		});

	};

	if (typeof define === 'function' && define.amd) {
		define("d3graph", ["d3"], d3graph);
	} else if ('undefined' !== typeof exports && 'undefined' !== typeof module) {
		module.exports = d3graph;
	} else {
		window.d3graph = d3graph;
	}
})(window);

function circleRadius(d, properties) {
	var countedRadius = properties.vertexSizeMax*(d.property/properties.maxVertexProperty);
	return (d.property && properties.maxVertexProperty) ? 
		Math.max(properties.vertexSizeMin, countedRadius) : properties.vertexSizeMin;
}

function strokeWidth(d, properties) {
	return (d.property) ? Math.max(3,10*(d.property/properties.maxEdgeProperty)) : 3;
}

function strokeOpacity(d, properties) {
	return (d.property) ? Math.max(0.3,(d.property/properties.maxEdgeProperty)) : 0.5;
}

function getCircleTransformTick(d) {
	return "translate(" + d.x + "," + d.y + ")";
}

function getPathTick(d, radiusArray) {
	var r = radiusArray[d.target.index];
	var dr = 0;
	var temp  = Math.sqrt(r * r * (d.source.y - d.target.y) * (d.source.y - d.target.y) / 
		((d.source.x - d.target.x)*(d.source.x - d.target.x) + (d.source.y - d.target.y)*(d.source.y - d.target.y)));

	var yr, xr;
	if (d.source.y < d.target.y) {
		yr = d.target.y - temp;
		xr = d.target.x - temp*(d.source.x - d.target.x)/(d.source.y - d.target.y);
	}
	else {
		yr = d.target.y + temp;
		xr = d.target.x + temp*(d.source.x - d.target.x)/(d.source.y - d.target.y);
	}
						
	return "M" + 
		d.source.x + "," + 
		d.source.y + "A" + 
		dr + "," + dr + " 0 0,1 " + 
		xr + "," + 
		yr;
}

function formatTooltip(d, verticesAttributes, properties, tooltipInfo) {
	var tooltipText = '';
				
	if (properties.vertexColor !== 'None' && properties.vertexColor !== null)
		tooltipText += formatColorInfo(d, verticesAttributes, properties);

	if (tooltipInfo !== null)
		tooltipText += formatTooltipTable(d, tooltipInfo, verticesAttributes);	

	return '<span class="tipsy-title">' + d.name + '</span><br/>' + "\n" + tooltipText;
}

function formatColorInfo(d, verticesAttributes, properties) {
	var colorLegend = (verticesAttributes[properties.vertexColor][d.index] !== null) ? 
						verticesAttributes[properties.vertexColor][d.index] : 'NA';
	var tooltipText = '<span style="text-align: left; font-size: 5em; color: ' + d.color;
	tooltipText += '">' + '&#9679' + '</span><p><b>' + colorLegend + '</b></p>';
	return tooltipText;
}

function formatTooltipTable(d, data, verticesAttributes) {
	var tooltipText = '<table>';

	for (i = 0; i < data.length; i++)
	{
		tooltipText += '<tr><td style="text-align: left">';
		tooltipText += data[i].toUpperCase() + '</td><td style="text-align: right">';
		tooltipText += formatAttribute(verticesAttributes[data[i]][d.index]);
		tooltipText += '</td></tr>';
	}
	tooltipText += '</table>';
	return tooltipText;
}

function formatAttribute(value) {
	return isNaN(value) ? value : Number(value).toFixed(2);
}
