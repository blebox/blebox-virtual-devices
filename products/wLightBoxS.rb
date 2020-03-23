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
      'device': {
        'deviceName': ENV.fetch('NAME'),
        'type': 'wLightBoxS',
        'fv': '0.924',
        'hv': '0.1',
        'universe': 0,
        'apiLevel': '20180718', # latest: '20180718'
        "id": 'a13e37e750b8',
        'ip': '192.168.9.13',
        'availableFv': None
      }
    }
  end

  def response_state
    {
      "currentColor": format('%02x', state.current),
      "desiredColor": format('%02x', state.desired)
      # TODO: add fadeSpeed, etc.
      # "fadeSpeed": format('%d', state.fade_speed)
    }
  end

  def from_post(data)
    state.desired = data.fetch('light').fetch('desiredColor').to_i(16)
  end
end

MyApp.run!
