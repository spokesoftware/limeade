module Limeade

  class Error < StandardError; end

  class InvalidResponseError < Error; end

  class InvalidCredentialsError < Error; end

  class DisconnectedError < Error
    def initialize
      super('Attempting to use a disconnected client to the LimeSurvey API')
    end
  end

  class ServerError < Error
    attr_reader :code, :response_error

    def initialize(code, message)
      @code = code
      @response_error = message
      super("Server error #{code}: #{message}")
    end
  end

  class APIError < Error
    def initialize(method, status)
      super("LimeSurvey API '#{method}' returned a failure status: #{status}")
    end
  end

end
