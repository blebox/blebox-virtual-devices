# frozen_string_literal: true

require 'singleton'

require_relative '../app'

class State
  include Singleton

  attr_accessor :desired
  attr_reader :current

  def initialize
    @current = 0
    @desired = 0
  end

  def tick
    @current += 1 if desired > current
    @current -= 1 if desired < current
  end
end

class MyApp < App
  class << self
    def state_url
      '/api/light/state'
    end

    def post_url
      '/api/rgbw/set'
    end

    def section_field
      'light'
    end

    def type
      'wLightBoxS'
    end
  end

  def tick
    state.tick
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
        "id": 'a13e37e750b8',
        "apiLevel": '20180718' # latest: '20180718'
      },
      "network": {
        "ip": self.class.ip,
        "ssid": 'myWiFiNetwork',
        "station_status": 5,
        "apSSID": 'wlightboxs-ap',
        "apPasswd": ''
      },
      "light": response_state
    }
  end

  def response_state
    {
      "currentColor": format('%02X', state.current),
      "desiredColor": format('%02X', state.desired)
      # TODO: add fadeSpeed, etc.
    }
  end

  def from_post(data)
    state.desired = data.fetch('light').fetch('desiredColor').to_i(16)
  end
end

MyApp.run!
