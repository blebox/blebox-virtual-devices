# frozen_string_literal: true

require 'singleton'

require_relative '../app'

class State
  include Singleton

  attr_reader :desired
  attr_reader :current

  attr_accessor :last_color

  def initialize
    @last_color = @current = @desired = 'ff000000'
  end

  def tick
    return if desired == current

    rawd = desired.to_i(16)
    rawc = current.to_i(16)

    rd = (rawd & 0xFF000000) >> 24
    rc = (rawc & 0xFF000000) >> 24
    rc += (rd > rc ? 1 : rc > rd ? -1 : 0)

    gd = (rawd & 0x00FF0000) >> 16
    gc = (rawc & 0x00FF0000) >> 16
    gc += (gd > gc ? 1 : gc > gd ? -1 : 0)

    bd = (rawd & 0x0000FF00) >> 8
    bc = (rawc & 0x0000FF00) >> 8
    bc += (bd > bc ? 1 : bc > bd ? -1 : 0)

    wd = (rawd & 0x000000FF)
    wc = (rawc & 0x000000FF)
    wc += (wd > wc ? 1 : wc > wd ? -1 : 0)

    @current = format('%08x', (((((rc << 8) | gc) << 8) | bc) << 8) | wc)
  end

  def off?
    desired == '00000000'
  end

  def turn_on
    @desired = last_color
  end

  def turn_off
    @desired = '00000000'
  end

  def toggle
    off? ? turn_on : turn_off
  end

  def desired=(new_color)
    @desired = @last_color = new_color
  end
end

class MyApp < App
  class << self
    def state_url
      '/api/rgbw/state'
    end

    def post_url
      '/api/rgbw/set'
    end

    def section_field
      'rgbw'
    end

    def type
      'wLightBox'
    end
  end

  def tick_interval
    0.07
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
        "fv": '0.247',
        "hv": '0.2',
        "id": '9afe34e750b8'
      },
      "network": {
        "ip": self.class.ip,
        "ssid": 'myWiFiNetwork',
        "station_status": 5,
        "apSSID": 'wLightBox-ap',
        "apPasswd": ''
      },
      "rgbw": response_state
    }
  end

  def response_state
    {
      "desiredColor": state.desired,
      "currentColor": state.current,
      "fadeSpeed": 248,
      "effectSpeed": 2,
      "effectID": 3,
      "colorMode": 3
    }
  end

  def from_post(data)
    state.desired = data.fetch('rgbw').fetch('desiredColor')
  end

  get '/s/onoff/last' do
    state.toggle
    state_as_json
  end

  get '/s/:color' do
    state.desired = params[:color]
    state_as_json
  end
end

MyApp.run!
