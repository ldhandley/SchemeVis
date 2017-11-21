require "json"

output = {}

Dir.glob("Level-*/**/responses.json").each do |file|
  parts = file.split("/")  

  prefix = parts[0..1].join("/")

  data = JSON.parse(`cat #{file}`)  
  output[prefix] = data
end

puts output.to_json
