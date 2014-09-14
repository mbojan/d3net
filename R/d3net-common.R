
reactiveNetwork <- function (outputId) 
{
  HTML(paste("<div id=\"", outputId, "\" class=\"shiny-network-output\"><svg /></div>", sep=""))
}

progressBar <- function ()
{
  HTML('<div id = "progressBar" class="span12" style="padding: 0 1em 0 1em;">
       <input id="slider" type ="range" min ="0" max="10" step ="1" value ="0" style="width: 100%;"/>
       </div>')
}
