# frozen_string_literal: true

require 'singleton'

require_relative '../app'

class State
  include Singleton

  attr_accessor :desired
  attr_reader :current

  def initialize
    @current = [0, 0]
    @desired = [0, 0]
  end

  def tick
    current.each_with_index do |value, index|
      @current[index] += 1 if desired[index] > value
      @current[index] -= 1 if desired[index] < value
    end
  end
end

class MyApp < App
  class << self
    def state_url
      '/api/gatecontroller/state'
    end

    def post_url
      '/api/gatecontroller/set'
    end

    def section_field
      'gateController'
    end

    def type
      'gateController'
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
        "apiLevel": '20180604',
        "fv": '0.247',
        "hv": '0.2',
        "id": '330ff7e750b8',
        "ip": self.class.ip
      }
    }
  end

  def response_state
    {
      "currentPos": state.current,
      "desiredPos": state.desired
      # TODO: more fields
    }
  end

  def from_post(data)
    values = data.fetch('gateController').fetch('desiredPos')
    raise NotImplementedError unless [1, 2].include?(values.size)

    values.each_with_index do |value, index|
      raise NotImplementedError unless (-1..100).include?(value)
      next if values == -1 # not change

      state.desired[index] = value
    end
  end

  # NOTE: recommended to use POST instead
  get '/s/p/:position' do
    # TODO: what happens if parameter is wrong?
    begin
      state.desired[0] = params.fetch(:position)
    rescue KeyError
      halt 400
    end

    state_as_json
  end
end

MyApp.run!
