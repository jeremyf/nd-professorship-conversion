require 'rest_client'
require 'json'

def get_json_response_for(path)
  RestClient.get("http://#{File.join('professorships.nd.edu', path).sub(/\/$/, '')}.js", {:params => {'children' => 'true'}, :accept => :json})
end

def parse_json_for(path)
  JSON.parse(get_json_response_for(path).body)
end


parse_json_for('/by-college')['children'].each do |college|
  college_name = college['name'].strip
  parse_json_for(college['permalink'])['children'].each do |professorship|
    chair_name      = professorship['meta_attributes']['chair'].strip
    professor_name  = professorship['meta_attributes']['name'].strip
    photo           = professorship['meta_attributes']['photo'].strip
    last_name       = professorship['meta_attributes']['lastnameprof'].strip
    biography       = professorship['meta_attributes']['bio'].strip
    chair_last_name = professorship['meta_attributes']['lastnametitle'].strip
  end
end
