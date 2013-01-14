require 'nokogiri'
require 'json'

svg = Nokogiri::XML(File.read('bubbles.svg'))
h = svg.xpath("//circle").map { |node| Hash[node.attributes.keys.zip(node.attributes.values.map(&:value))] }
File.open("bubbles.json", "w") { |f| f.write h.to_json }
