# frozen_string_literal: true

require 'singleton'

require_relative '../app'

class State
  include Singleton

  attr_accessor :desired
  attr_reader :current

  attr_accessor :temperature

  def initialize
    @current = 0
    @desired = 0
    @temperature = 23
  end

  def tick
    @current += 1 if desired > current
    @current -= 1 if desired < current
  end
end

class MyApp < App
  class << self
    def state_url
      '/api/dimmer/state'
    end

    def post_url
      '/api/dimmer/set'
    end

    def section_field
      'dimmer'
    end

    def type
      'dimmerBox'
    end
  end

  def tick
    state.tick
  end

  def tick_interval
    0.1
  end

  def state
    State.instance
  end

  def uptime_response
    { "uptime": uptime_miliseconds }
  end

  def device_state
    {
      "device": {
        "deviceName": ENV.fetch('NAME'),
        "type": self.class.type,
        "fv": '0.247',
        "hv": '0.2',
        "id": '183e37e750b8',
        "apiLevel": '20180604'
      },
      "network": {
        "ip": self.class.ip,
        "ssid": 'myWiFiNetwork',
        "station_status": 5,
        "apSSID": 'dimmerBox-ap',
        "apPasswd": ''
      },
      "dimmer": response_state
    }
  end

  def response_state
    {
      "loadType": 7,
      "currentBrightness": state.current,
      "desiredBrightness": state.desired,
      "temperature": state.temperature,
      "overloaded": false,
      "overheated": false
    }
  end

  def from_post(data)
    state.desired = data.fetch('dimmer').fetch('desiredBrightness')
  end
end

MyApp.run!
