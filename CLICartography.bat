echo off
rem  Command line cartography by Mike Bostock @ https://medium.com/@mbostock/command-line-cartography-part-1-897aa8f8ca2c
rem  Process for optimizing Shapefiles for web through geojson and TopoJson

rem INSTALL THESE DEPENDENCIES  - npm from node.js
rem npm install -g shapefile 
rem npm install -g d3-geo-projection
rem npm install -g ndjson-cli
rem npm install -g topojson
rem npm install -g d3

rem INPUT 
SET /P _inputSHP= Please enter the name of input .shp:
SET /P _SHPidField= Enter the name of the column containing unique identifiers for every feature:
SET /P _outputJson= Please enter a name for the output JSON:
SET /P _outputWidth= Enter the width, the svg output should be scaled to: 
SET /P _outputHeight= Enter the height, the svg output should be scaled to: 

rem Shapefile to ndjson
shp2json %_inputSHP%.shp | geoproject "d3.geoIdentity().reflectY(true).fitSize([%_outputWidth%, %_outputHeight%], d)" | ndjson-split "d.features" | ndjson-map "d.id = d.properties.%_SHPidField%, d" > %_outputJson%.ndjson

rem MISSING CSV DATA JOIN

rem GEO TO TOPO PART - Assuming already projected .shp
geo2topo -n tracts=%_outputJson%.ndjson |  toposimplify -p 1 -f | topoquantize 1e5 > %_outputJson%-topo.json

rem TOPO TO SVG
topo2geo tracts=- < %_outputJson%-topo.json | ndjson-map -r d3 "z = d3.scaleSequential(d3.interpolateViridis).domain([0, 98]), d.features.forEach(f => f.properties.fill = z(f.properties.%_SHPidField%)), d" | ndjson-split "d.features" | geo2svg -n --stroke none -p 1 -w %_outputWidth% -h %_outputHeight% > %_outputJson%-color.svg

rem TOPO TO GEO
topo2geo tracts=- < %_outputJson%-topo.json | geoproject "d3.geoIdentity().reflectY(true).fitSize([%_outputWidth%, %_outputHeight%], d)" > %_outputJson%-Geo.json

@pause