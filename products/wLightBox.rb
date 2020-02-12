# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'
require 'json'

SERVER = `/sbin/ip route`.lines[-1].split(' ')[-1]
set :port, 80

ID='1afe34e750b8'
TYPE='wLightBox'
STATE_PATH = '/api/rgbw/state'

STDERR.puts "#{TYPE} at #{SERVER}"

class State
  attr_reader :start

  attr_accessor :desired
  attr_reader :current

  attr_accessor :last_color
  def initialize
    @start = Time.now.to_i

    @desired = 'ff000000'
    @current = 'ff000000'
    @last_color = @desired
  end

  def tick
    return if @desired == @current
    rawd = @desired.to_i(16)
    rawc = @current.to_i(16)

    rd = (rawd & 0xFF000000) >> 24
    rc = (rawc & 0xFF000000) >> 24
    rc += (rd > rc ? 1 : rc > rd ? -1 : 0 )

    gd = (rawd & 0x00FF0000) >> 16
    gc = (rawc & 0x00FF0000) >> 16
    gc += (gd > gc ? 1 : gc > gd ? -1 : 0 )

    bd = (rawd & 0x0000FF00) >> 8
    bc = (rawc & 0x0000FF00) >> 8
    bc += (bd > bc ? 1 : bc > bd ? -1 : 0 )

    @current = (((((rc << 8) | gc) << 8) | bc) << 8).to_s(16)
  end

  def color=(newcolor)
    @desired = @last_color = newcolor
  end

  def is_off
    return @desired == "00000000"
  end

  def turn_on
    @desired = @last_color
  end

  def turn_off
    @desired = "00000000"
  end

  def uptime_seconds
    Time.now.to_i - start
  end
end

def state
  $state ||= State.new
end

get '/api/device/uptime' do
  json("uptimeS": state.uptime_seconds)
end

def rgbw_state
  {
    "desiredColor": state.desired,
    "currentColor": state.current,
    "fadeSpeed": 248,
    "effectSpeed": 2,
    "effectID": 3,
    "colorMode": 3
  }
end

def state_as_json
  json("rgbw": rgbw_state)
end

get '/api/device/state' do
  # sleep(15)
  json(
    "device": {
      "deviceName": ENV.fetch('NAME'),
      "type": TYPE,
      "fv": '0.247',
      "hv": '0.2',
      "id": ID
    },
    "network": {
      "ip": SERVER,
      "ssid": 'myWiFiNetwork',
      "station_status": 5,
      "apSSID": 'wLightBox-ap',
      "apPasswd": ''
    },
    "rgbw": rgbw_state
  )
end

get STATE_PATH do
  state_as_json
end

get '/s/onoff/last' do
  if state.is_off
    state.turn_on
  else
    state.turn_off
  end

  state_as_json
end

get '/s/:color' do
  state.desired = params[:color]
  state_as_json
end

Thread.new do
  loop do
    sleep 0.07
    state.tick
  end
end
