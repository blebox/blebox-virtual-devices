# frozen_string_literal: true

require 'singleton'

require_relative '../app'

class State
  include Singleton

  attr_reader :desired
  attr_reader :current

  attr_accessor :last_on_color

  def initialize
    @last_on_color = @current = @desired = 'ff000000'
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
    @desired = last_on_color
  end

  def turn_off
    @desired = '00000000'
  end

  def toggle
    off? ? turn_on : turn_off
  end

  def desired=(new_color)
    @desired = new_color
    off = '00000000'
    @last_on_color = new_color unless new_color == off
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
        "flavor": self.class.type,
        "hv": 'smartLight-85mm-1.0',
        "fv": '0.998.1.umdns.dgn',
        "universe": 3,
        "id": '9afe34e750b8',
        # 'ip': '192.168.0.20',
        # 'availableFv': nil
        # TODO: is the layout ok for this apiLevel version?
        "apiLevel": '20180718' # latest: '20190808',
      }
    }
  end

  def response_state
    # NOTE: apiLevel "20190808":
    # {
    #  'desiredColor': '000000ff',
    #  'currentColor': '000000ff',
    #  'lastOnColor': '000000ff',
    #  'durationsMs': {
    #    'colorFade': 2975,
    #    'effectFade': 1000,
    #    'effectStep': 1000
    #  },
    #  'effectID': 0,
    #  'colorMode': 1
    # }

    {
      "desiredColor": state.desired,
      "currentColor": state.current,
      "lastOnColor": state.last_on_color,
      # TODO: newer durationMs structure here (like above)
      # "fadeSpeed": 248,
      # "effectSpeed": 2,
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
