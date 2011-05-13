require 'rest_client'
require 'json'
require 'active_support/core_ext/hash'

def get_json_response_for(path)
  RestClient.get("http://#{File.join('professorships.nd.edu', path).sub(/\/$/, '')}.js", {:params => {'children' => 'true'}, :accept => :json})
end

def parse_json_for(path)
  JSON.parse(get_json_response_for(path).body)
end

# Realistically, instead of storing these in memory, we would
# store them in a more permanent location
@chairs = {}
@directorships = {}

# Build the initial collection of professorships.
parse_json_for('/by-college')['children'].each do |college|

  college_name = college['name'].strip

  parse_json_for(college['permalink'])['children'].each do |professorship|
    chair_name      = professorship['meta_attributes']['chair'].strip
    prof_name       = professorship['meta_attributes']['name'].strip
    prof_photo      = professorship['meta_attributes']['photo'].strip
    prof_last_name  = professorship['meta_attributes']['lastnameprof'].strip
    prof_biography  = professorship['meta_attributes']['bio'].strip
    chair_last_name = professorship['meta_attributes']['lastnametitle'].strip
    permalink       = professorship['permalink']
    prof_first_name = prof_name.sub(prof_last_name, '').strip
    @chairs[chair_name] ||= []
    @chairs[chair_name] << {
      'chair_name'      => chair_name,
      'prof_full_name'  => prof_name,
      'prof_first_name' => prof_first_name,
      'prof_last_name'  => prof_last_name,
      'prof_biography'  => prof_biography,
      'prof_photo'      => prof_photo,
      'chair_last_name' => chair_last_name,
      'permalink'       => permalink,
      'chair'           => true,
      'directorship'    => false,
    }
  end
end

# Build the intial collection of directorships
parse_json_for('/directorships')['children'].each do |directorship|
  chair_name      = directorship['meta_attributes']['chair'].strip
  prof_name       = directorship['meta_attributes']['name'].strip
  prof_photo      = directorship['meta_attributes']['photo'].strip
  prof_last_name  = directorship['meta_attributes']['lastnameprof'].strip
  prof_biography  = directorship['meta_attributes']['bio'].strip
  chair_last_name = directorship['meta_attributes']['lastnametitle'].strip
  permalink       = directorship['permalink']
  prof_first_name = prof_name.sub(prof_last_name, '').strip

  @directorships[chair_name] ||= []
  @directorships[chair_name] << {
    'chair_name'      => chair_name,
    'prof_full_name'  => prof_name,
    'prof_first_name' => prof_first_name,
    'prof_last_name'  => prof_last_name,
    'prof_biography'  => prof_biography,
    'prof_photo'      => prof_photo,
    'chair_last_name' => chair_last_name,
    'permalink'       => permalink,
    'chair'           => false,
    'directorship'    => true,
  }
end

# Looks like we have duplicate data to consider.  This is how we are going to
# check
@duplicate_chairs = @chairs.select {|k,v| v.size > 1}
@duplicate_directorships = @directorships.select {|k,v| v.size > 1}

