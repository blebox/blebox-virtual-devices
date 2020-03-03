# frozen_string_literal: true

require 'singleton'

require_relative '../app'

class State
  include Singleton

  attr_accessor :desired
  attr_reader :current
  attr_reader :state

  FULL_OPEN = 0
  FULL_CLOSE = 100

  STATE_DOWN_CLOSING = 0
  STATE_UP_OPENING = 1
  STATE_MANUALLY_STOPPED = 2
  STATE_CLOSE_LIMIT = 3
  STATE_OPEN_LIMIT = 4

  # Visual (e.g. 75% = 75% closed):
  #
  # ____ (0) - open / upper limit
  # ||||
  # ||||
  # ****
  #
  # ____ (100) - closed / lower limit

  def initialize
    @current = FULL_OPEN # full open
    @desired = FULL_OPEN
    @state = STATE_OPEN_LIMIT
  end

  def tick
    @current += 1 if desired > current
    @current -= 1 if desired < current

    @state = calculate_state
  end

  def calculate_state
    return STATE_DOWN_CLOSING if desired > current
    return STATE_UP_OPENING if desired < current
    return STATE_CLOSE_LIMIT if current == FULL_CLOSE
    return STATE_OPEN_LIMIT if current == FULL_OPEN

    STATE_MANUALLY_STOPPED
  end
end

class MyApp < App
  class << self
    def state_url
      '/api/shutter/state'
    end

    def post_url
      '/api/shutter/set'
    end

    def section_field
      'shutter'
    end

    def type
      'shutterBox'
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
        "fv": '0.247',
        "hv": '0.2',
        "id": '5a3e37e750b8',
        "ip": self.class.ip,
        "apiLevel": '20180604'
      }
    }
  end

  def response_state
    {
      "state": state.state,
      "currentPos": {
        "position": state.current,
        "tilt": -1
      },
      "desiredPos": {
        "position": state.desired,
        "tilt": -1
      },
      "favPos": {
        "position": 13, # TODO: implement?
        "tilt": -1
      }
    }
  end

  def from_post(data)
    state.desired = data.fetch('shutter').fetch('desiredPos').fetch('position')
    # TODO: implement tilt handling?
  end

  get '/s/:command/:parameter' do
    command = params[:command]
    value = params[:parameter]
    halt(400, 'not implemented yet') if command != 'p'

    percentage =
      begin
        Integer(value)
      rescue ArgumentError
        warn "bad parameter: #{command.inspect}"
        halt 400, 'bad param'
      end

    halt(400, "out of range: #{percentage}") if percentage > 100
    halt(400, "out of range: #{percentage}") if percentage.negative?

    state.desired = percentage

    state_as_json
  end

  get '/s/:command' do
    command = params[:command]

    case command
    when 'u' # up
      state.desired = State::FULL_OPEN
    when 'd' # down
      state.desired = State::FULL_CLOSE
    when 's' # stop
      state.desired = state.current
    else
      halt(400, "#{command.inspect} not implemented yet")
    end

    state_as_json
  end
end

MyApp.run!
