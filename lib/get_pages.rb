require 'rest_client'
require 'json'
require 'active_support/core_ext/hash'
require 'yaml'

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
@colleges = {}
parse_json_for('/professorships/colleges')['data'].each do |response|
  @colleges[response['college']] = response['id']
end

# Build the initial collection of professorships.
parse_json_for('/by-college')['children'].each do |college|

  college_name = college['name'].strip

  parse_json_for(college['permalink'])['children'].each do |professorship|
    chair_name       = professorship['meta_attributes']['chair'].strip
    prof_name        = professorship['meta_attributes']['name'].strip
    professorship['meta_attributes']['photo'].strip =~ /src="([^"]*)"/
    prof_photo      = $1
    prof_last_name   = professorship['meta_attributes']['lastnameprof'].strip
    prof_biography   = professorship['meta_attributes']['bio'].strip
    chair_last_name  = professorship['meta_attributes']['lastnametitle'].strip
    permalink        = professorship['permalink']
    prof_first_name  = prof_name.sub(prof_last_name, '').strip
    college_id = nil
    unless college_id = @colleges[college_name]
      puts "Warning: no college for #{permalink}"
    end
    @chairs[chair_name] ||= []
    @chairs[chair_name] << {
      'chair_name'      => chair_name,
      'prof_full_name'  => prof_name,
      'prof_first_name' => prof_first_name,
      'prof_last_name'  => prof_last_name,
      'prof_biography'  => prof_biography,
      'photo_upload'    => prof_photo,
      'chair_last_name' => chair_last_name,
      'permalink'       => permalink,
      'college_name'    => college_name,
      'college_id'      => college_id,
      'chair'           => true,
      'directorship'    => false,
    }
  end
end

# Build the intial collection of directorships
parse_json_for('/directorships')['children'].each do |directorship|
  chair_name      = directorship['meta_attributes']['chair'].strip
  prof_name       = directorship['meta_attributes']['name'].strip
  directorship['meta_attributes']['photo'].strip =~ /src="([^"]*)"/
  prof_photo      = $1
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
    'photo_upload'    => prof_photo,
    'chair_last_name' => chair_last_name,
    'permalink'       => permalink,
    'college_id'      => nil,
    'chair'           => false,
    'directorship'    => true,
  }
end

File.open(File.join(File.dirname(__FILE__), '..','tmp/chairs.yml'), 'w+') do |file|
  file.puts(YAML.dump(@chairs))
end

File.open(File.join(File.dirname(__FILE__), '..','tmp/colleges.yml'), 'w+') do |file|
  file.puts(YAML.dump(@colleges))
end

File.open(File.join(File.dirname(__FILE__), '..','tmp/directorships.yml'), 'w+') do |file|
  file.puts(YAML.dump(@directorships))
end