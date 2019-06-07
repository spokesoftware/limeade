require 'limeade/version'
require 'limeade/errors'
require 'limeade/client'
require 'limeade/json_rpc'
require 'logger'

module Limeade

  def self.logger
    @logger ||= ::Logger.new($stdout)
  end

  def self.logger=(logger)
    @logger = logger
  end

end
