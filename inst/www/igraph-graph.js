
var networkOutputBinding = new Shiny.OutputBinding();
  $.extend(networkOutputBinding, {

	find: function(scope) {
	  return $(scope).find('.shiny-network-output');
	},
	
	renderValue: function(el, data) {
		var properties = getProperties(data);
		var projectionColors = getProjectionColors(data.vertices, data.verticesAttributes, properties);
	  	var nodes = getNodes(data.vertices, data.verticesAttributes, properties, projectionColors);
	  	var edges = data.links;
	  	properties.maxVertexProperty = maxVertexProperty(nodes) || 0;
	  	properties.maxEdgeProperty = maxEdgeProperty(edges) || 0;

	  
	  var vertices = data.vertices;
	  var tooltipInfo = data.tooltipInfo;
	  var verticesAttributes = data.verticesAttributes;

	  

	  //var zoomButtonHtml = '<button type="button" class="btn btn-default btn-lg" id="zoomButton">Zooming</button>'
	  //$("#player").html(zoomButtonHtml);
	  //$("#logo").removeAttr("style");

	  d3graph.generate(el, properties, nodes, edges, verticesAttributes, tooltipInfo);
	  
	}

  });

/**
  Interval for indicating whether shiny is busy
  Shows loading image when R is doing stuff
  */
setInterval(function(){
	if ($('html').attr('class')=='shiny-busy') {
		setTimeout(function() {
			if ($('html').attr('class')=='shiny-busy') 
				$('div.busy').show();	
	  	}, 1000);
	} 
	else 
		$('div.busy').hide();
}, 100);

function maxVertexProperty(data) {
	return data.reduce(function(acc, vertex) { 
		if (Number(vertex.property) > acc) 
		  return Number(vertex.property); 
		else return acc}, 0);
}

function maxEdgeProperty(data) {
	return data.reduce(function(acc, edge) { 
		if (Number(edge.property) > acc) 
		  return Number(edge.property); 
		else return acc;  }, 0)
}

function getProperties(data) {
	var properties = data.d3 || {};
	properties.vertexRadius = data.vertexRadius;
	properties.vertexColor 	= data.vertexColor;
	properties.graphType 	= data.graphType;
	properties.width 		= 7/12* $(window).width();
	properties.height 		= 0.75 * $(window).height();
	properties.markerSize	= 3;
	return properties;
}

function getProjectionColors(vertices, verticesAttributes, properties) {
	var minColor = 'lightyellow';
	var colorScalePicker = d3.scale.category10().domain(d3.range(0,10));
	var scale = d3.scale.linear().range([colorScalePicker(properties.color), minColor]);
	var stringsForColoring = getUniqueVertciesValue(vertices, verticesAttributes, properties);
	var projectionColors = {};

  	for (var stringId in stringsForColoring) {
  		if (!projectionColors[stringsForColoring[stringId]])
	  		projectionColors[stringsForColoring[stringId]] = scale(stringId/stringsForColoring.length);
  	}

  	return projectionColors;
}

function getUniqueVertciesValue(data, dataAttr, properties) {
	var stringsForColoring = [];

	for (var i = 0; i < data.length; i++){
		value = (properties.vertexColor !== 'None' && properties.vertexColor !== null) ? 
				dataAttr[properties.vertexColor][i] : 'NA';
		stringsForColoring.push(value);
	}

  	// leave only unique elements
  	stringsForColoring = stringsForColoring.filter(function(elem, pos, self) {
	  	return self.indexOf(elem) == pos;
  	});

  	return stringsForColoring;
}

function getNodes(vertices, verticesAttributes, properties, projectionColors) {
	if (!vertices || !verticesAttributes)
		return [];
	var nodes = [];
	for (var i = 0; i < vertices.length; i++) {
		value = (properties.vertexColor !== 'None' && properties.vertexColor !== null) ? 
				verticesAttributes[properties.vertexColor][i] : 'NA';
		property = (properties.vertexRadius !== 'None' && properties.vertexRadius !== null) ? 
				verticesAttributes[properties.vertexRadius][i] : null;
		nodes.push({"name": vertices[i], "property" : property, "color" : projectionColors[value]});
	}
	return nodes;
}
Shiny.outputBindings.register(networkOutputBinding, 'pawluczuk.networkbinding');