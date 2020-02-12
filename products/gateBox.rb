# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'
require 'json'

SERVER = `/sbin/ip route`.lines[-1].split(' ')[-1]
set :port, 80

ID = '233ff7e750b8'
TYPE = 'gateBox'
STATE_PATH = '/api/gate/state'

STDERR.puts "#{TYPE} at #{SERVER}"

# TODO: gate index number

class State
  attr_reader :start

  attr_reader :desired
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

  def primary
    @desired = desired.zero? ? 100 : 0
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
    "deviceName": ENV.fetch('NAME'),
    "type": TYPE,
    "fv": '0.247',
    "hv": '0.2',
    "id": ID,
    "ip": SERVER
  )
end

def state_as_json
  json(
    "currentPos": state.current,
    "desiredPos": state.desired
    # TODO: more fields
  )
end

def state_as_json2
  json(
    "gate": {
      "currentPos": state.current,
      "desiredPos": state.desired
      # TODO: more fields
    }
  )
end

get STATE_PATH do
  state_as_json
end

get '/s/:parameter' do
  # TODO: what happens if parameter is wrong?
  STDERR.puts params.inspect
  STDERR.puts params[:parameter].inspect
  if params[:parameter] == 'p'
    STDERR.puts "(PRIMARY)"
    state.primary
  end

  state_as_json2
end

Thread.new do
  loop do
    sleep 0.3
    state.tick
  end
end
