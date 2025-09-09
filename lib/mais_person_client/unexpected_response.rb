# frozen_string_literal: true

class MaisPersonClient
  # Handles unexpected responses when communicating with Mais
  class UnexpectedResponse
    # Error raised when the Mais API returns a 401 Unauthorized
    class UnauthorizedError < StandardError; end

    # Error raised when the Mais API returns a 500 error
    class ServerError < StandardError; end

    # Error raised when the Mais API returns a response with an error message in it
    class ResponseError < StandardError; end

    def self.call(response)
      case response.status
      when 401
        raise UnauthorizedError, "There was a problem with authentication: #{response.body}"
      when 500
        raise ServerError, "Mais server error: #{response.body}"
      else
        raise StandardError, "Unexpected response: #{response.status} #{response.body}"
      end
    end
  end
end
