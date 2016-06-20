window.addEventListener("load", function() {
   
   
   function officialAchievementsHtmlFetcher() {
       if (this.readyState === 4) {
           var bodyChildrenHtml = extractBodyDescendantHtml(this.responseText.trim());
           addTextToNonvisibleElement(bodyChildrenHtml);
           enableGraphResizing();
           createChart(getD3GraphData());
       }
   }
   
   function enableGraphResizing() {
     window.addEventListener("resize", function() {
       var nodes = [document.querySelector(".tooltip"), document.querySelector("svg")];
       for (var i = 0; i < nodes.length; i++) {
         var node = nodes[i];
         if (node) {
           node.parentNode.removeChild(node);
         }
       }
       createChart(getD3GraphData());
     });
   }
   
   function extractBodyDescendantHtml(str) {
       var pattern = /(<body.*>)/;
       var begin_index = str.search(pattern) + str.match(pattern)[0].length;
       var end_index = str.indexOf("</body");
       return str.slice(begin_index, end_index);
   }
   
   function addTextToNonvisibleElement(str) {
       document.getElementById("temp-container").innerHTML = str;
   }
   
   function getD3GraphData() {
       var achievement_image_list = document.querySelectorAll(".achieveImgHolder img");
       var achievement_percentage_list = document.querySelectorAll(".achievePercent");
       var achievement_name_list = document.querySelectorAll(".achieveTxt h3");
       var achievement_description_list = document.querySelectorAll(".achieveTxt h5");
       var d3_data_list = [];
       for (var i = 0; i < achievement_image_list.length; i++) {
           d3_data_list.push({
              image: achievement_image_list.item(i).src,
              percent: achievement_percentage_list.item(i).textContent,
              name: achievement_name_list.item(i).textContent,
              description: achievement_description_list.item(i).textContent
           });
       }
       return d3_data_list;
   }
   
   function createChart(dataList) {
        
        var chart = d3.select(".chart")
          
        var tooltip = d3.select(".chart")
          .append("div")
          .classed("tooltip uk-width-small-1-1 uk-width-medium-1-4", true);
          
        var svg = d3.select(".chart")
          .append("svg")
          .classed("uk-width-small-1-1 uk-width-medium-3-4", true);
        
        var width = d3.select("svg").node().clientWidth;
        var diameter = width;
        
        var bubbleNodes = d3.layout.pack()
          .sort(null)
          .size([diameter, svg.node().clientHeight])
          .padding(2);
        
        var data = dataList.map(function(curr) {
            curr.value = curr.percent.slice(0, curr.percent.length - 1);
            return curr;
        });
        
        var nodeTree = bubbleNodes.nodes({children: data})
        .filter(function(curr) {
            return !curr.children;
        });
        
        var dataValues = data.map(function(curr) {
            return curr.value;
        });
        
        var scale = d3.scale.category20c()
          .domain([d3.min(dataValues), d3.max(dataValues)]);
               
        var bubbles = svg.append("g")
          .attr("transform", "translate(0,0)")
          .selectAll(".bubble")
          .data(nodeTree)
          .enter();
        
        var circles = bubbles.append("circle")
          .attr("r", function(d) {
            return d.r;
          })
          .attr("cx", function(d) {
            return d.x;
          })
          .attr("cy", function(d) {
            return d.y;
          })
          .style({
            fill: function(d) {
               return scale(d.value);
            }
            
          })
          .on("mouseover", function(d) {
            tooltip.node().innerHTML = "<img src=\"" + d.image +
            "\">" + "<p>" + d.name + "</p>" + "<p>" + d.description
            + "</p>" + "<p>" + d.percent + "</p>";
          });
        
        bubbles.append("text")
          .attr("x", function(d) {
            return d.x;
          })
          .attr("y", function(d) {
            return d.y;
          })
          .attr("text-anchor", "middle")
          .text(function(d) {
            return d.name.slice(0, d.r / 4);
          })
          .style("font-size", "1em");
        
        
        
        
   }
   
   var req = createXHRRequest("GET", "/getxcomachievementsrawhtml", 
   officialAchievementsHtmlFetcher);
   req.send();
});