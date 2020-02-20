# frozen_string_literal: true

require 'singleton'

require_relative '../app'

class State
  include Singleton

  attr_reader :temperature

  def initialize
    @temperature = 2000
  end

  def tick
    @temperature = 1000 + ((Time.now.to_i % 4000) - 2000).abs
  end
end

class MyApp < App
  class << self
    def state_url
      '/api/tempsensor/state'
    end

    def section_field
      'tempSensor'
    end

    def type
      'tempSensor'
    end
  end

  def tick
    state.tick
  end

  def state
    State.instance
  end

  def uptime_response
    { "uptimeS": uptime_seconds }
  end

  def device_state
    {
      "device": {
        "deviceName": ENV.fetch('NAME'),
        "type": self.class.type,
        "fv": '0.176',
        "hv": '0.6',
        "id": '8afe34db9437',
        "ip": self.class.ip,
        "apiLevel": '20180604'
      }
    }
  end

  def response_state
    {
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
  end
end

MyApp.run!
