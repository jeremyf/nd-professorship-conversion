require 'rest_client'
require 'json'
require 'active_support/core_ext/hash'
require 'yaml'
require 'highline'


@host = 'professorships.nd.edu'
@protocol = 'https'
# @host = 'localhost:3000'
# @protocol = 'http'

def get_json_response_for(path)
  puts path
  RestClient.get("#{@protocol}://#{File.join(@host, path).sub(/\/$/, '')}.js", {:params => {'children' => 'true'}, :accept => :json})
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
    professorship_title       = professorship['meta_attributes']['chair'].strip
    prof_name        = professorship['meta_attributes']['name'].strip
    professorship['meta_attributes']['photo'].strip =~ /src="([^"]*)"/
    prof_photo      = $1
    professor_last_name   = professorship['meta_attributes']['lastnameprof'].strip
    biography   = professorship['meta_attributes']['bio'].strip
    professorship_last_name  = professorship['meta_attributes']['lastnametitle'].strip
    permalink        = professorship['permalink']
    professor_first_name  = prof_name.sub(professor_last_name, '').strip
    college_id = nil
    unless college_id = @colleges[college_name]
      puts "Warning: no college for #{permalink}"
    end
    @chairs[professorship_title] ||= []
    @chairs[professorship_title] << {
      'professorship_title'      => professorship_title,
      'prof_full_name'  => prof_name,
      'professor_first_name' => professor_first_name,
      'professor_last_name'  => professor_last_name,
      'biography'  => biography,
      'photo_upload'    => prof_photo,
      'professorship_last_name' => professorship_last_name,
      'permalink'       => permalink,
      'college_name'    => college_name,
      'college'      => college_id,
      'chair'           => true,
      'directorship'    => false,
    }
  end
end

# Build the intial collection of directorships
parse_json_for('/directorships')['children'].each do |directorship|
  professorship_title      = directorship['meta_attributes']['chair'].strip
  prof_name       = directorship['meta_attributes']['name'].strip
  directorship['meta_attributes']['photo'].strip =~ /src="([^"]*)"/
  prof_photo      = $1
  professor_last_name  = directorship['meta_attributes']['lastnameprof'].strip
  biography  = directorship['meta_attributes']['bio'].strip
  professorship_last_name = directorship['meta_attributes']['lastnametitle'].strip
  permalink       = directorship['permalink']
  professor_first_name = prof_name.sub(professor_last_name, '').strip

  @directorships[professorship_title] ||= []
  @directorships[professorship_title] << {
    'professorship_title'      => professorship_title,
    'prof_full_name'  => prof_name,
    'professor_first_name' => professor_first_name,
    'professor_last_name'  => professor_last_name,
    'biography'  => biography,
    'photo_upload'    => prof_photo,
    'professorship_last_name' => professorship_last_name,
    'permalink'       => permalink,
    'college'      => nil,
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

# Merging the data
@directorships.each do |key, entry|
  if @chairs.has_key?(key)
    @chairs[key].each do |chair|
      chair['directorship'] = true
    end
  else
    @chairs[key] = entry
  end
end

@database_id = 6
@highline = HighLine.new

def net_id
  @net_id ||= @highline.ask(@highline.color("Net ID: ", :black, :on_yellow))
end

def password
  @password ||= @highline.ask(@highline.color("Password: ", :black, :on_yellow)) { |q| q.echo = "*" }
end


File.open(File.join(File.dirname(__FILE__), '..','tmp/chairs-for-upload.yml'), 'w+') do |file|
  file.puts(YAML.dump(@chairs))
end

net_id
password
@chairs.each do |professorship_title, entries|
  entries.each_with_index do |entry, index|
    begin
      RestClient.post(
      "#{@protocol}://#{@net_id}:#{@password}@#{@host}/admin/data_store_models/#{@database_id}/records",
      {
        "without_expire" => 'true',
        "record" => {
          'directorship'            => entry['directorship'],
          'professorship_title'     => entry['professorship_title'],
          'professorship_last_name' => entry['professorship_last_name'],
          'professor_first_name'    => entry['professor_first_name'],
          'professor_last_name'     => entry['professor_last_name'],
          'biography'               => entry['biography'],
          'photo_upload'            => entry['photo_upload'],
          'college'                 => entry['college'],
          'sequence'                => index + 1
        }
      }, {:accept => :xml}
      )
    rescue RestClient::Found => e
      puts e.response.headers[:location]
    rescue RestClient::RequestFailed => e
      # we have a bigger problem
      require 'ruby-debug'; debugger; true;
    end
  end
end
