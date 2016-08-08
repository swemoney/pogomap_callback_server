
## Receive callbacks from PokemonGO Map

A very simple Sinatra server that listens for callbacks from the PokemonGo-Map project
(https://github.com/PokemonGoMap/PokemonGo-Map) and parses the pokemon seen to send to
the IFTTT notification channel.

## Disclaimer

This has been tested a little bit on an Ubuntu VPS but that's about it. It should work
anywhere you can install Ruby, Sinatra and Redis, but I make no guaruntees.

## Requirements

* Ruby
* Rubygems
* Redis Server

## Installation

Google is your friend when in doubt.

1. Install Ruby on your platform of choice
2. Install Redis on your platform of choice and start the server
3. Clone this repo where you want to run the server from
4. `bundle install`
5. `cp app_config.json.example app_config.json`
6. `rackup` (or `ruby app.rb` if you have rails 5 and rack/sinatra aren't playing nice together yet)

You should be up and running at this point.

## Configuration

All of the configuration options you should need are available in the `app_config.json` file but the
`app.rb` file is also very small so you should be able to tweak anything you'd like if things aren't
exactly how you like them.

###### Options

* `notifications`: These are options related to what you want to be notified about.
    * `lowest_spawn_rate`: The lowest spawn rate you want to be notified. You can see all of the spawn rates in pokemon.json.
    * `extra_pokemon_ids`: Array of ids for any pokemon that has a lower spawn rate that you specified, but you still want to be notified about them.
    * `ignored_pokemon_ids`: Array of ids for pokemon that you never want to be notified about (this will supersede `extra_pokemon_ids`).
* `home`: The coordinates for where we'll calculate distance from. For example, your front door.
    * `latitude`: Latitude of your `home`
    * `longitude`: Longitude of your `home`
* `ifttt`: IFTTT specific settings. This app uses the IFTTT Maker channel. (https://ifttt.com/maker)
    * `maker_channel_key`: Your maker channel key.
    * `maker_channel_event`: The event_name you gave your recipe
* `redis`: Redis configuration
    * `server_url`: The URL for your Redis server
    * `cache_timeout`: How long we store each encounter_id. I decided 1800 was a good number even though pokemon aren't around for longer than 15 minutes.
* `pokemon`: If you have a pokemon.json file that you'd prefer to use. You probably won't change this as the format would have to be pretty similar to the one included here.

## Enjoy

This was whipped together quickly. There may be issues with it but it's been running nicely on my server
and working great for a little while. If you have issues, feel free to fork and submit a pull request or
just modify it to your hearts content.
