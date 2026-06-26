# frozen_string_literal: true

require "net/http"
require "uri"

module TogoWS
  class Client
    MAX_REDIRECTS = 5
    USER_AGENT = "togows/#{VERSION}".freeze

    def initialize(base_url, timeout)
      @base_url = base_url
      @timeout = timeout
    end

    def get(path)
      uri = URI.parse(URLBuilder.full_url(@base_url, path))
      request(uri) do |http, request_uri|
        req = Net::HTTP::Get.new(request_uri)
        apply_headers(req)
        http.request(req)
      end
    end

    def post(path, body)
      uri = URI.parse(URLBuilder.full_url(@base_url, path))
      request(uri) do |http, request_uri|
        req = Net::HTTP::Post.new(request_uri)
        apply_headers(req)
        req["Content-Type"] = "text/plain"
        req.body = body
        http.request(req)
      end
    end

    private

    def request(uri, redirects = 0, &)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = @timeout
      http.read_timeout = @timeout

      response = http.start { |h| yield h, uri.request_uri }
      if response.is_a?(Net::HTTPRedirection) && redirects < MAX_REDIRECTS
        return request(redirect_uri(uri, response), redirects + 1, &)
      end

      raise HTTPError.new(response.code, response.message, response.body) unless response.is_a?(Net::HTTPSuccess)

      response.body
    end

    def redirect_uri(uri, response)
      location = response["location"]
      raise HTTPError.new(response.code, response.message, response.body) if location.nil? || location.empty?

      uri + location
    end

    def apply_headers(request)
      request["User-Agent"] = USER_AGENT
    end
  end
end
