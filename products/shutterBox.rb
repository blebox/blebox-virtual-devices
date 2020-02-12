# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'
require 'json'

SERVER = `/sbin/ip route`.lines[-1].split(' ')[-1]
set :port, 80

ID = '6a3e37e750b8'
TYPE = 'shutterBox'
STATE_PATH = '/api/shutter/state'
API_LEVEL = '20180604'

STDERR.puts "#{TYPE} at #{SERVER}"

class State
  attr_reader :start

  attr_accessor :desired
  attr_reader :current

  def initialize
    @start = Time.now.to_i

    @current = 0
    @desired = 0
  end

  def uptime_seconds
    Time.now.to_i - start
  end

  def tick
    @current += 1 if desired > current
    @current -= 1 if desired < current
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
      "fv": '0.247',
      "hv": '0.2',
      "id": ID,
      "ip": SERVER,
      "apiLevel": API_LEVEL
    }
  )
end

def state_as_json
  json(
    "shutter": {
      "state": 4,
      "currentPos": {
        "position": state.current,
        "tilt": -1
      },
      "desiredPos": {
        "position": state.desired,
        "tilt": -1
      },
      "favPos": {
        "position": 13,
        "tilt": -1
      }
    }
  )
end

get STATE_PATH do
  state_as_json
end

get '/s/:command/:parameter' do
  $stderr.puts "---------------------- #{params.inspect}"
  halt 400 if params[:command] != 'p'

  percentage =
    begin
      Integer(params[:parameter])
    rescue ArgumentError
      warn "bad parameter: #{params[:parameter].inspect}"
      halt 400, 'bad param'
    end

  halt(400, "out of range: #{percentage}") if percentage > 100
  halt(400, "out of range: #{percentage}") if percentage < 0

  $stderr.puts "---------------------- #{percentage}"

  state.desired = percentage

  state_as_json
end

Thread.new do
  loop do
    sleep 0.3
    state.tick
  end
end
