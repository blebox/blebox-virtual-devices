# frozen_string_literal: true

require 'singleton'

require_relative '../app'

class State
  include Singleton

  attr_accessor :desired

  attr_reader :temperature
  attr_accessor :on

  def initialize
    @on = true
    @temperature = 2500
    @desired = 7126
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
      if temperature > 2500
        @temperature -= 9
      else
        @temperature += (Time.now.sec > 30 ? 3 : -3)
      end
    end
  end
end

class MyApp < App
  class << self
    def state_url
      '/api/heat/state'
    end

    def post_url
      '/api/heat/set'
    end

    def section_field
      'heat'
    end

    def type
      'saunaBox'
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
        "apiLevel": '20180604',
        "id": '4afe34db94f7',
        "ip": self.class.ip
      }
    }
  end

  def response_state
    {
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
  end

  def from_post(data)
    heat = data.fetch('heat')
    state.on = heat.fetch('state') == 1

    # handle optional temperature field
    begin
      state.desired = heat.fetch('desiredTemp')
    rescue KeyError
    end
  end

  get '/s/t/:temperature' do
    state.desired = Integer(params[:temperature])

    state_as_json
  end

  get '/s/:command' do
    command = params[:command]
    case command
    when '0', 'false'
      state.on = false
    when '1', 'true'
      state.on = true
    else
      halt 400
    end

    state_as_json
  end
end

MyApp.run!
