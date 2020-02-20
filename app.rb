# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/json'
require 'json'

class App < Sinatra::Base
  set :port, 80
  set :dump_errors, true

  class << self
    def ip
      @ip ||= `/sbin/ip route`.lines[-1].split(' ')[-1]
    end

    def started_at
      @started_at ||= Time.now.to_f
    end
  end

  def initialize
    self.class.started_at # init

    warn "#{self.class.type} at #{self.class.ip}"

    self.class.get self.class.state_url do
      state_as_json
    end

    if self.class.respond_to?(:post_url)
      self.class.post self.class.post_url do
        begin
          from_post(JSON.parse(request.body.read))
        rescue KeyError => e
          halt 400, e.to_s
        end

        state_as_json
      end
    end

    Thread.new do
      loop do
        sleep tick_interval
        tick
      end
    end
  end

  def tick_interval
    0.3
  end

  def uptime_miliseconds
    (uptime_raw_seconds * 1000.0).to_i
  end

  def uptime_raw_seconds
    Time.now.to_f - self.class.started_at
  end

  def uptime_seconds
    Time.now.to_i - self.class.started_at.to_i
  end

  get '/api/device/uptime' do
    json(uptime_response)
  end

  get '/api/device/state' do
    json(device_state)
  end

  def state_as_json
    json(self.class.section_field => response_state)
  end
end
