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

  STATE_CLOSING = 0
  STATE_OPENING = 1
  STATE_MANUALLY_STOPPED = 2
  STATE_CLOSE_LIMIT = 3
  STATE_OPEN_LIMIT = 4
  STATE_OVERLOAD = 5
  STATE_MOTOR_FAILURE = 6
  STATE_SAFETY_STOP = 8

  # TODO: not implemented correctly for MOTORS == 2
  MOTORS = 1

  # Visual (e.g. 75% = 75% closed):
  #
  # (100 - close limit) [   <=====] (0 - open limit)

  def initialize
    # 0 = full open, 100 = full close
    @current = [FULL_OPEN] * MOTORS
    @desired = [FULL_OPEN] * MOTORS
    @state = STATE_OPEN_LIMIT
  end

  def tick
    current.each_with_index do |value, index|
      @current[index] += 1 if desired[index] > value
      @current[index] -= 1 if desired[index] < value
    end
    @state = calculate_state
  end

  def calculate_state
    # TODO: first motor
    return STATE_CLOSING if desired[0] > current[0]
    return STATE_OPENING if desired[0] < current[0]
    return STATE_CLOSE_LIMIT if current[0] == FULL_CLOSE
    return STATE_OPEN_LIMIT if current[0] == FULL_OPEN

    STATE_MANUALLY_STOPPED
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
        "apiLevel": '20180604', # latest: '20190911'
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
      "desiredPos": state.desired,
      "state": state.state
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
      pos = params.fetch(:position)
      state.desired = [pos] * State::MOTORS
    rescue KeyError
      halt 400
    end

    state_as_json
  end

  get '/s/:command' do
    command = params[:command]

    case command
    when 'o' # open
      state.desired = [State::FULL_OPEN] * State::MOTORS
    when 'c' # close
      state.desired = [State::FULL_CLOSE] * State::MOTORS
    when 's' # stop
      state.desired = state.current
    else
      halt(400, "#{command.inspect} not implemented yet")
    end

    state_as_json
  end
end

MyApp.run!
