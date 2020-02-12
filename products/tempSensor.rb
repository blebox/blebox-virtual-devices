# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'
require 'json'

SERVER = `/sbin/ip route`.lines[-1].split(' ')[-1]
set :port, 80

ID='1afe34db9437'
TYPE='tempSensor'
API_LEVEL='20180604'
STATE_PATH='/api/tempsensor/state'

STDERR.puts "#{TYPE} at #{SERVER}"

class State
  attr_reader :start

  attr_reader :temperature

  def initialize
    @start = Time.now.to_i
    @temperature = 2000

    @thread = Thread.new do
      loop do
        sleep 0.3
        state.tick
      end
    end
  end

  def uptime_seconds
    Time.now.to_i - start
  end

  def tick
    @temperature = 1000 + ((Time.now.to_i % 4000) - 2000).abs
  end

end

def state
  $state ||= State.new
end

get '/api/device/uptime' do
  json("uptimeS": state.uptime_seconds)
end

get '/api/device/state' do
  json(
    "device": {
      "deviceName": ENV.fetch('NAME'),
      "type": TYPE,
      "fv": '0.176',
      "hv": '0.6',
      "id": ID,
      "ip": SERVER,
      "apiLevel": API_LEVEL,
    }
  )
end

def state_as_json
  json(
    "tempSensor": {
      "sensors": [
        {
          "type": 'temperature',
          "id": 0,
          # "value": 1890,
          "value": state.temperature,
          "trend": 3,
          "state": 2,
          "elapsedTimeS": 0
        }
      ]
    }
  )
end

get STATE_PATH  do
  state_as_json
end


Thread.new do
  loop do
    sleep 0.3
    state.tick
  end
end
