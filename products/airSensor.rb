# frozen_string_literal: true

require 'singleton'

require_relative '../app'

class State
  include Singleton

  def initialize
    @timers = 3.times.map { Time.now.to_i }
    @values = [3, 90, 6]
  end

  def tick; end

  def elapsed(index)
    Time.now.to_i - timers[index]
  end

  def value(index)
    @values[index]
  end

  def kick
    @timers = 3.times.map { Time.now.to_i }
    @values[0] = Time.now.to_i % 10
    @values[1] = (Time.now.to_i + 13) % 20
    @values[2] = (Time.now.to_i + 27) % 60
  end

  private

  attr_reader :timers
  attr_reader :values
end

class MyApp < App
  class << self
    def state_url
      '/api/air/state'
    end

    def section_field
      'air'
    end

    def type
      'airSensor'
    end
  end

  def tick
    state.tick
  end

  def state
    State.instance
  end

  def device_state
    {
      "device": {
        "deviceName": ENV.fetch('NAME'),
        "type": self.class.type,
        "fv": '0.176',
        "hv": '0.6',
        "id": '04fe34db9437',
        "ip": self.class.ip,
        "apiLevel": '20180403' # latest: '20191112'
      }
    }
  end

  def response_state
    {
      "sensors": [
        {
          "type": 'pm1',
          "value": state.value(0),
          "trend": 2,
          "state": 0,
          "qualityLevel": -1,
          "elaspedTimeS": state.elapsed(0)
        },
        {
          "type": 'pm2.5',
          "value": state.value(1),
          "trend": 0,
          "state": 0,
          "qualityLevel": 1,
          "elaspedTimeS": state.elapsed(1)
        },
        {
          "type": 'pm10',
          "value": state.value(2),
          "trend": 1,
          "state": 3,
          "qualityLevel": 1,
          "elaspedTimeS": state.elapsed(2)
        }
      ]
    }
  end

  get '/api/device/uptime' do
    halt 404
  end

  get '/api/air/runtime' do
    factor = 6 # 20 minutes per hour of work hours
    json("runtime": uptime_seconds / (3600 * factor))
  end

  get '/api/air/kick' do
    state.kick
    status 204
  end
end

MyApp.run!
