# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'
require 'json'

SERVER = `/sbin/ip route`.lines[-1].split(' ')[-1]
set :port, 80

ID = '883e37e750b8'
TYPE = 'dimmerBox'
STATE_PATH = '/api/dimmer/state'
API_LEVEL = '20180604'

STDERR.puts "#{TYPE} at #{SERVER}"

class State
  attr_reader :start

  attr_accessor :desired
  attr_accessor :temperature
  attr_reader :current

  def initialize
    @start = Time.now.to_f

    @current = 0
    @desired = 0
    @temperature = 23;
  end

  def tick
    @current += (desired > current ? 1 : (desired < current ? -1 : 0))
  end

  def uptime_seconds
    Time.now.to_f - start
  end
end

def state
  $state ||= State.new
end

get '/api/device/uptime' do
  json("uptime": state.uptime_seconds * 1000.0)
end

get '/api/device/state' do
  json(
    "device": {
      "deviceName": ENV.fetch('NAME'),
      "type": TYPE,
      "fv": '0.247',
      "hv": '0.2',
      "id": ID,
      "apiLevel": API_LEVEL
    },
    "network": {
        "ip": SERVER,
        "ssid": "myWiFiNetwork",
        "station_status": 5,
        "apSSID": "dimmerBox-ap",
        "apPasswd": ""
    },
    "dimmer": {
        "loadType": 7,
        "currentBrightness": state.current,
        "desiredBrightness": state.desired,
        "temperature": state.temperature,
        "overloaded": false,
        "overheated": false
    }
  )
end

def dimmer_state
  {
    "loadType": 7,
    "currentBrightness": state.current,
    "desiredBrightness": state.desired,
    "temperature": state.temperature,
    "overloaded": false,
    "overheated": false
  }
end

def state_as_json
  json( "dimmer": dimmer_state)
end

get STATE_PATH do
  state_as_json
end

post '/api/dimmer/set' do
  data = JSON.parse(request.body.read)
  data = data.fetch('dimmer')

  begin
    state.desired = data.fetch('desiredBrightness')
  rescue KeyError
    # TODO: find matching error status here
  end

  state_as_json
end

Thread.new do
  loop do
    sleep 0.3
    state.tick
  end
end
