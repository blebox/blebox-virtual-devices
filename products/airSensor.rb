# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'
require 'json'

SERVER = `/sbin/ip route`.lines[-1].split(' ')[-1]
set :port, 80

ID='34fe34db9437'
TYPE='airSensor'
API_LEVEL='20180604'
STATE_PATH='/api/air/state'

STDERR.puts "#{TYPE} at #{SERVER}"

class State
  attr_reader :start
  attr_reader :temperature

  def initialize
    @start = Time.now.to_i
    @timers = 3.times.map { Time.now.to_i }
		@values = [3,90,6]

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
  end

	def elapsed(index)
    Time.now.to_i - @timers[index]
	end

	def value(index)
		@values[index]
	end

	def kick
    @timers = 3.times.map { Time.now.to_i }
    @values[0] = Time.now.to_i % 10
    @values[1] = Time.now.to_i + 13 % 20
    @values[2] = Time.now.to_i + 27 % 60
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
	 "air": {
		 "sensors": [
			 {
				 "type": "pm1",
				 "value": state.value(0),
				 "trend": 2,
				 "state": 0,
				 "qualityLevel": -1,
				 "elaspedTimeS": state.elapsed(0)
			 },
			 {
				 "type": "pm2.5",
				 "value": state.value(1),
				 "trend": 0,
				 "state": 0,
				 "qualityLevel": 1,
				 "elaspedTimeS": state.elapsed(1)
			 },
			 {
				 "type": "pm10",
				 "value": state.value(2),
				 "trend": 1,
				 "state": 3,
				 "qualityLevel": 1,
				 "elaspedTimeS": state.elapsed(2)
			 }
		 ]
	 }
  )
end

get STATE_PATH  do
  state_as_json
end

get '/api/air/kick' do
	state.kick
  status 204
end

Thread.new do
  loop do
    sleep 0.3
    state.tick
  end
end
