# frozen_string_literal: true

require 'faraday'
require 'multi_json'

module Limeade
  # An implementation of JSON RPC version 1. This is inspired by jsonrpc-client, which implements
  # version 2 of the spec. This implementation adds retry capability via Faraday::Request::Retry.

  class JSON_RPC
    JSON_RPC_VERSION = '1.0'

    #
    # Instantiate a client and setup a connection to the endpoint.
    # Passes configuration for the Faraday::Request::Retry mechanism.
    # @see Faraday::Request::Retry
    #
    # @param retry_options [Hash] The options for Faraday::Request::Retry.
    # @option retry_options [Integer] :max (2) Maximum number of retries.
    # @option retry_options [Float] :interval (0) Pause in seconds between retries.
    # @option retry_options [Float] :interval_randomness (0) The maximum random interval amount
    #   expressed as a float between 0 and 1 to use in addition to the interval.
    # @option retry_options [Float] :max_interval (Float::MAX) An upper limit for the interval.
    # @option retry_options [Float] :backoff_factor (1) The amount to multiply each successive
    #   retry's interval amount by in order to provide backoff.
    # @option retry_options [Array<Error, String>] :exceptions ([Errno::ETIMEDOUT, 'Timeout::Error',
    #   Error::TimeoutError, Faraday::Error::RetriableResponse]) The list of exceptions
    #   to handle. Exceptions can be given as Class, Module, or String.
    # @option retry_options [Array<Symbol>] :methods (Faraday::Request::Retry::IDEMPOTENT_METHODS)
    #   A list of HTTP methods to retry without calling retry_if.  Pass an empty Array to call
    #   retry_if for all exceptions.
    # @option retry_options [Proc] :retry_if (return false) Block that will receive the env object
    #   and the exception raised and decides whether to retry regardless of the retry count.
    #   This would be useful if the exception produced is non-recoverable or if the the HTTP method
    #   called is not idempotent.
    # @option retry_options [Proc] :retry_block Block that is executed after every retry. Request
    #   environment, middleware options, current number of retries and the exception are passed to
    #   the block as parameters.
    #
    # @raise [ServerError] The API endpoint server is having issues. An error code and message are
    #   included.
    # @raise [InvalidResponseError] The API endpoint is returning malformed JSON RPC responses.
    #   A descriptive message details the problem.
    # @raise [URI::InvalidURIError] The API endpoint URI is not valid.
    def initialize(endpoint, retry_options = {})
      @uri = ::URI.parse(endpoint).to_s     # Ensure that endpoint is a valid URI
      @retry_options = retry_options || {}  # Ensure not nil
    end

    # Send the request with the specified method and arguments
    # @param method [Symbol] the method to invoke
    # @param args [Array] the arguments to the method
    # @return the results of the call
    def invoke(method, *args)
      Limeade.logger.debug "invoke(#{method}, #{args.inspect})"
      request_id = make_id
      post_data = ::MultiJson.encode({
                                         'jsonrpc' => JSON_RPC_VERSION,
                                         'method'  => method,
                                         'params'  => args,
                                         'id'      => request_id
                                     })
      response = connection.post(@uri, post_data, STANDARD_HEADERS)

      Limeade.logger.debug "API response: #{response.inspect}"

      process_response(response, request_id)
    end

    private

    STANDARD_HEADERS = { content_type: 'application/json' }.freeze

    def connection
      @connection ||= ::Faraday.new do |connection|
        connection.request :retry, @retry_options
        connection.response :logger, Limeade.logger
        connection.adapter ::Faraday.default_adapter
      end
    end

    def process_response(response, request_id)
      verify_response(response)
      payload = payload_from(response)
      verify_payload(payload, request_id)
      raise ServerError.new(payload['error']['code'], payload['error']['message']) if payload['error']

      payload['result']
    end

    def verify_response(response)
      Limeade.logger.debug "verify_response: #{response.inspect}"
      raise(InvalidResponseError, 'Response is nil') if response.nil?
      raise(InvalidResponseError, 'Response body is nil') if response.body.nil?
      raise(InvalidResponseError, 'Response body is empty') if response.body.empty?
    end

    def verify_payload(payload, request_id)
      Limeade.logger.debug "verify_payload: #{payload.inspect}"
      raise(InvalidResponseError, 'Response body is not a Hash') unless payload.is_a?(::Hash)
      raise(InvalidResponseError, 'Response body is missing the id') unless payload.key?('id')
      raise(InvalidResponseError, "Response id (#{payload['id']}) does not match request id (#{request_id})") unless payload['id'] == request_id
      raise(InvalidResponseError, 'Response body must have a result and an error') unless payload.key?('error') && payload.key?('result')

      if payload['error']
        error = payload['error']
        raise(InvalidResponseError, 'Response error is not a Hash') unless error.is_a?(::Hash)
        raise(InvalidResponseError, 'Response error is missing the code') unless error.key?('code')
        raise(InvalidResponseError, 'Response error code is not a number') unless error['code'].is_a?(::Integer)
        raise(InvalidResponseError, 'Response error is missing the message') unless error.key?('message')
        raise(InvalidResponseError, 'Response error message is not a string') unless error['message'].is_a?(::String)
      end
    end

    def payload_from(response)
      ::MultiJson.decode(response.body)
    rescue StandardError => e
      Limeade.logger.info "Failed to parse JSON from:\n#{response.body}"
      raise InvalidResponseError, e.message
    end

    def make_id
      rand(10**12)
    end
  end
end
