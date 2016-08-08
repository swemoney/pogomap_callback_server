require 'sinatra'
require 'json'
require 'httparty'
require 'geokit'
require 'redis'
require 'uri'

set :port, 4999

configure do
  # Read our config file
  if File.file? 'app_config.json'
    CONFIG = JSON.parse File.read('app_config.json')
  else
    raise 'Can not find "app_config.json" file. Try copying the app_config.json.example to get started.'
  end

  # Setup Redis
  uri = URI.parse(CONFIG['redis']['server_url'])
  REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

  # Setup our pokemon data
  POKEMON = JSON.parse File.read(CONFIG['pokemon']['json_file'])

  # Setup some home coords
  HOME_COORDS = Geokit::LatLng.new(CONFIG['home']['latitude'], CONFIG['home']['longitude'])
  Geokit::default_units = :meters

  # Setup home bounds if we're using them
  if CONFIG['home']['bounds']['use_bounds'] == true
    HOME_BOUNDS = Geokit::Bounds.new(
      Geokit::LatLng.new(CONFIG['home']['bounds']['SW']['latitude'], CONFIG['home']['bounds']['SW']['longitude']),
      Geokit::LatLng.new(CONFIG['home']['bounds']['NE']['latitude'], CONFIG['home']['bounds']['NE']['longitude'])
    )
  end
end

post '/pogowebhook' do
  # Parse the JSON we got
  data = JSON.parse(request.body.read)

  # Grab the encounter_id
  encounter_id = data['message']['encounter_id']

  # We don't want to worry about multiple encounters of the same pokemon
  unless REDIS.exists(encounter_id)

    # Get some pokemon data
    pokemon_id  = data['message']['pokemon_id'].to_s
    pokemon_lat = data['message']['latitude']
    pokemon_lng = data['message']['longitude']
    pokemon     = POKEMON[pokemon_id]

    # Set the key in Redis so we ignore this guy next time
    REDIS.set    encounter_id, pokemon['name']
    REDIS.expire encounter_id, CONFIG['redis']['cache_timeout']

    # Check the spawnrate and ignored/extra pokemon we want notifications for
    if (CONFIG['notifications']['extra_pokemon_ids'].include? pokemon_id.to_i) ||
      (pokemon['spawn_rate'].to_i >= CONFIG['notifications']['lowest_spawn_rate'])

      unless (CONFIG['notifications']['ignored_pokemon_ids'].include? pokemon_id.to_i)
        if in_bounds(pokemon_lat, pokemon_lng)

          destination = "#{pokemon_lat},#{pokemon_lng}"
          distance    = HOME_COORDS.distance_to destination
          heading     = HOME_COORDS.heading_to destination
          heading_str = degrees_to_compass(heading)

          post_to_ifttt CONFIG['ifttt']['maker_channel_event'], # event_name: Maker Channel event_name
                        "#{pokemon['name']} (##{pokemon_id})",  # Value1: Pokemon Name
                        pokemon['rarity'].downcase,             # Value2: Pokemon rarity
                        "#{distance.round}m #{heading_str}"     # Value3: Distance and heading

        end
      end
    end

  end
end

def in_bounds(lat, lng)
  return true if CONFIG['home']['bounds']['use_bounds'] == false
  return true if HOME_BOUNDS.contains?(Geokit::LatLng.new lat, lng)
  return false
end

def degrees_to_compass(degrees)
  compass_num    = ((degrees / 22.5) + 0.5).to_i
  compass_points = ['N','NNE','NE','ENE','E','ESE','SE','SSE','S','SSW','SW','WSW','W','WNW','NW','NNW']
  compass_points[(compass_num % 16)]
end

def post_to_ifttt(event_name, value1, value2, value3)
  post_body = { value1: value1, value2: value2, value3: value3 }.to_json
  url       = "https://maker.ifttt.com/trigger/#{event_name}/with/key/#{CONFIG['ifttt']['maker_channel_key']}"
  HTTParty.post(url, body: post_body, headers: { "Content-Type": "application/json" })
end
