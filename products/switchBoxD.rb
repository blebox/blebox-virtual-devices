# frozen_string_literal: true

require 'singleton'

require_relative '../app'

class State
  include Singleton

  attr_accessor :states
  attr_accessor :states_after_restart
  attr_accessor :names

  def initialize
    @states = [0, 0]
    @states_after_restart = [0, 0]
    @names = ['relay 0', 'relay 1']
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
      'switchBoxD'
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
        "id": '6334f7e750b8',
        "ip": self.class.ip
      }
    }
  end

  def response_state
    [0, 1].map do |index|
      {
        "relay": index,
        "state": state.states[index],
        "stateAfterRestart": state.states_after_restart[index],
        "name": state.names[index]
      }
    end
  end

  def from_post(data)
    data.fetch('relays').each do |relay_data|
      relay = relay_data.fetch('relay')

      raise NotImplementedError unless [0, 1].include?(relay)

      state.states[relay] = relay_data.fetch('state')
      state.states_after_restart[relay] = relay_data.fetch('stateAfterRestart')
      state.names[relay] = relay_data.fetch('stateAfterRestart')
    end
  end

  # NOTE: prefer POST method instead
  get '/s/:relay/:state' do
    relay =
      begin
        Integer(params[:relay])
      rescue ArgumentError
        halt 400, "bad relay: #{params[:relay].inspect}"
      end
    value = params[:state]

    case value
    when '0', 'false'
      state.states[relay] = 0
    when '1', 'true'
      state.states[relay] = 1
    else
      halt 400, "unknown relay state value: #{value.inspect}"
    end

    state_as_json
  end
end

MyApp.run!
