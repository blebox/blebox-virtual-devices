# frozen_string_literal: true

require 'singleton'

require_relative '../app'

class State
  include Singleton

  attr_accessor :state
  attr_accessor :state_after_restart

  def initialize
    @state = 0
    @state_after_restart = 0
  end

  def tick; end
end

class MyApp < App
  class << self
    def state_url
      '/api/relay/state'
    end

    def post_url
      '/api/relay/set'
    end

    def section_field
      'relays'
    end

    def type
      'switchBox'
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
        "id": '7334f7e750b8',
        "apiLevel": '20180604' # latest: '20190808'

      },
      "network": {
        "ip": self.class.ip,
        "ssid": 'myWiFiNetwork',
        "station_status": 5,
        "apSSID": 'switchBox-ap',
        "apPasswd": ''
      },
      "relays": response_state
    }
  end

  def response_state
    [
      {
        "relay": 0,
        "state": state.state,
        "stateAfterRestart": state.state_after_restart
      }
    ]
  end

  def from_post(data)
    data.fetch('relays').each do |relay_data|
      relay = relay_data.fetch('relay')

      raise NotImplementedError unless [0].include?(relay)

      state.state = relay_data.fetch('state')
      state.state_after_restart = relay_data.fetch('stateAfterRestart')
    end
  end

  # NOTE: prefer POST method instead
  get '/s/:state' do
    value = params[:state]

    case value
    when '0', 'false'
      state.state = 0
    when '1', 'true'
      state.state = 1
    else
      halt 400, "unknown relay state value: #{value.inspect}"
    end

    state_as_json
  end
end

MyApp.run!
