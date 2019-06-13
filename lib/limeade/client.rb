require 'limeade/methods'

module Limeade

  # Client for accessing the LimeSurvey RemoteControl API from Ruby.
  class Client

    #
    # Instantiate a client and setup a connection to the LimeSurvey RemoteControl API.
    # Passes configuration for the Faraday::Request::Retry mechanism.
    # @see Faraday::Request::Retry
    #
    # @param endpoint [String] The URI for your account's API.
    # @param username [String] The username for your account.
    # @param password [String] The password for your account.
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
    # @raise [InvalidCredentialsError] The username and password combination is not valid.
    # @raise [ServerError] The API endpoint server is having issues. An error code and message are
    #   included.
    # @raise [InvalidResponseError] The API endpoint is returning malformed JSON RPC responses.
    #   A descriptive message details the problem.
    # @raise [URI::InvalidURIError] The API endpoint URI is not valid.
    def initialize(endpoint, username, password, retry_options = {})
      @json_rpc = Limeade::JSON_RPC.new(endpoint, retry_options)
      @username = username
      @password = password
      @session_key = get_session_key
    end

    # Is the client ready to send requests to the endpoint?
    # @return [Boolean] true if the client is ready; false otherwise.
    def connected?
      @session_key && @json_rpc
    end

    # Release resources for this client locally and at the endpoint.
    # @return [Boolean] true if the resources were released; false if client has already disconnected.
    def disconnect
      if connected?
        release_session_key
        @json_rpc = nil
        @session_key = nil
        true
      else
        false
      end
    end

    # Handle LimeSurvey RemoteControl API calls invoked on the client by invoking them on the endpoint.
    # @param method [Symbol] the method invoked
    # @param arguments [Array] the arguments to the method
    #
    # @raise [ServerError] The API endpoint server is having issues. An error code and message are included.
    # @raise [InvalidResponseError] The API endpoint is returning malformed JSON RPC responses. A descriptive message
    #
    # @return [Object] the result of invoking the method on the endpoint
    def method_missing(method, *arguments)
      if API_METHODS.include? method
        process_request(method, *arguments)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      API_METHODS.include?(method_name) || super
    end

    private

    # Send an LimeSurvey RemoteControl API call to the endpoint and handle the response.
    # @param method [Symbol] the method invoked
    # @param arguments [Array] the arguments to the method
    #
    # @raise [ServerError] The API endpoint server is having issues. An error code and message are included.
    # @raise [InvalidResponseError] The API endpoint is returning malformed JSON RPC responses. A descriptive message
    #
    # @return [Object] the result of invoking the method on the endpoint
    def process_request(method_name, *arguments)
      raise DisconnectedError unless connected?
      result = @json_rpc.invoke(method_name, @session_key, *arguments)
      if result.is_a? Hash and result['status']
        case result['status']
        when 'OK'
          true
        when 'No surveys found'
          []
        when 'No Tokens found'
          []
        when 'No survey participants table'
          false
        when /(left to send)|(No candidate tokens)$/
          result
        when /Invalid surveyid$/i
          nil
        when /Invalid session key$/i
          raise NoSessionError
        else
          raise APIError.new(method_name, result['status'])
        end
      else
        result
      end
    rescue NoSessionError
      # Get a fresh session and retry the call.
      @session_key = get_session_key
      retry
    end

    # Get a session key from the endpoint
    #
    # @raise [InvalidCredentialsError] The username and password combination is not valid.
    # @raise [ServerError] The API endpoint server is having issues. An error code and message are included.
    # @raise [InvalidResponseError] The API endpoint is returning malformed JSON RPC responses. A descriptive message
    #   details the problem.
    #
    # @return [String] the session key
    def get_session_key
      response = @json_rpc.invoke(:get_session_key, @username, @password)
      raise(InvalidCredentialsError, (response['status'] || response.inspect)) if response.is_a?(Hash)
      response
    end

    # Release a session key on the endpoint
    #
    # @raise [ServerError] The API endpoint server is having issues. An error code and message are included.
    # @raise [InvalidResponseError] The API endpoint is returning malformed JSON RPC responses. A descriptive message
    #
    # @return [String] "OK"
    def release_session_key
      @json_rpc.invoke(:release_session_key, @session_key)
    end
  end

  # Private exception raised only in the context of #process_request.
  class NoSessionError < Error; end

end
