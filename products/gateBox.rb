# frozen_string_literal: true

require 'singleton'

require_relative '../app'

class State
  include Singleton

  attr_reader :desired
  attr_reader :current

  attr_reader :extra_button_type

  def initialize
    @current = 0
    @desired = 0
    @extra_button_type = 1 # stop
  end

  def tick
    @current += 1 if desired > current
    @current -= 1 if desired < current
  end

  def primary
    @desired = desired.zero? ? 100 : 0
  end

  def secondary
    @desired = current
  end
end

class MyApp < App
  class << self
    def state_url
      '/api/gate/state'
    end

    def section_field
      'gate'
    end

    def type
      'gateBox'
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
      "deviceName": ENV.fetch('NAME'),
      "type": self.class.type,
      "fv": '0.247',
      "hv": '0.2',
      "id": '233ff7e750b8',
      "ip": self.class.ip
    }
  end

  def response_state
    {
      "currentPos": state.current,
      "desiredPos": state.desired,
      "extraButtonType": state.extra_button_type
      # TODO: more fields
    }
  end

  def state_as_json
    # NOTE: non-standard, because no section name
    json(response_state)
  end

  get '/s/:parameter' do
    case params[:parameter]
    when 'p'
      state.primary
    when 's'
      state.secondary
    else
      raise NotImplementedError
    end

    # NOTE: should be state_as_json, except default impl is non-standard
    json(self.class.section_field => response_state)
  end
end

MyApp.run!
