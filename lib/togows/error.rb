# frozen_string_literal: true

module TogoWS
  class Error < StandardError; end

  class HTTPError < Error
    attr_reader :code, :message_text, :body

    def initialize(code, message_text, body)
      @code = code.to_i
      @message_text = message_text
      @body = body.to_s
      super("#{code} #{message_text}")
    end
  end
end
