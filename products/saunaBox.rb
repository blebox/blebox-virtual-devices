# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'
require 'json'

SERVER = `/sbin/ip route`.lines[-1].split(' ')[-1]
set :port, 80

ID = 'aafe34db94f7'
TYPE = 'saunaBox'
STATE_PATH = '/api/heat/state'
API_LEVEL = '20180604'

STDERR.puts "#{TYPE} at #{SERVER}"

class State
  attr_reader :start

  attr_accessor :desired
  attr_reader :temperature
  attr_accessor :on

  def initialize
    @start = Time.now.to_i
    @on = true
    @temperature = 2500
    @desired = 7126
  end

  def uptime_seconds
    Time.now.to_i - start
  end

  def tick
    if on
      if (desired - temperature).abs < 90
        @temperature = desired
      else
        @temperature += 41 if desired > temperature
        @temperature -= 41 if desired < temperature
      end
    else
      if @temperature > 2500
        @temperature -= 9
      else
        @temperature += (Time.now.sec > 30 ? 3 : -3)
      end
    end
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
      "apiLevel": API_LEVEL,
      "id": ID,
      "ip": SERVER
    }
  )
end

def state_as_json
  json(
    "heat": {
      "state": state.on ? 1 : 0,
      "desiredTemp": state.desired,
      "sensors": [
        {
          "type": 'temperature',
          "id": 0,
          "value": state.temperature,
          "trend": 0,
          "state": 2,
          "elapsedTimeS": 0
        }
      ]
    }
  )
end

get STATE_PATH do
  state_as_json
end

get '/s/t/:temperature' do
  state.desired = Integer(params['temperature'])

  state_as_json
end

post '/api/heat/set' do
  data = JSON.parse(request.body.read)
  data = data.fetch('heat')

  begin
    state.on = data.fetch('state') == 1
  rescue KeyError
    # TODO: find matching error status here
  end

  begin
    state.desired = data.fetch('desiredTemp')
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
