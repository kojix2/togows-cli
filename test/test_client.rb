# frozen_string_literal: true

require_relative "test_helper"

class TestClient < Minitest::Test
  FakeHTTPSuccess = Struct.new(:body) do
    def is_a?(klass)
      klass == Net::HTTPSuccess || super
    end
  end

  FakeHTTPRedirect = Struct.new(:code, :message, :location, :body) do
    def is_a?(klass)
      klass == Net::HTTPRedirection || super
    end

    def [](name)
      name.downcase == "location" ? location : nil
    end
  end

  FakeHTTPFailure = Struct.new(:code, :message, :body) do
    def is_a?(klass)
      klass == Net::HTTPSuccess ? false : super
    end
  end

  class FakeHTTP
    attr_reader :host, :port, :requests
    attr_accessor :open_timeout, :read_timeout, :use_ssl

    def initialize(host, port, *responses)
      @host = host
      @port = port
      @responses = responses
      @requests = []
    end

    def start
      yield self
    end

    def request(request)
      @requests << [
        request.method,
        request.path,
        request["User-Agent"],
        request["Content-Type"],
        request.body
      ]
      @responses.shift
    end
  end

  def test_client_can_be_initialized
    client = TogoWS::Client.new("http://togows.org", 1)
    assert_instance_of TogoWS::Client, client
  end

  def test_get_requests_path_and_returns_body
    fake_http = FakeHTTP.new("togows.org", 443, FakeHTTPSuccess.new("ok"))
    client = TogoWS::Client.new("https://togows.org", 5)

    Net::HTTP.stub(:new, fake_http) do
      assert_equal "ok", client.get("/entry/pubmed/1")
    end

    assert_equal "togows.org", fake_http.host
    assert_equal 443, fake_http.port
    assert fake_http.use_ssl
    assert_equal 5, fake_http.open_timeout
    assert_equal 5, fake_http.read_timeout
    assert_equal [["GET", "/entry/pubmed/1", "togows/#{TogoWS::VERSION}", nil, nil]], fake_http.requests
  end

  def test_post_sends_plain_text_body
    fake_http = FakeHTTP.new("togows.org", 80, FakeHTTPSuccess.new("converted"))
    client = TogoWS::Client.new("http://togows.org", 5)

    Net::HTTP.stub(:new, fake_http) do
      assert_equal "converted", client.post("/convert/genbank.gff", "LOCUS")
    end

    refute fake_http.use_ssl
    assert_equal [["POST", "/convert/genbank.gff", "togows/#{TogoWS::VERSION}", "text/plain", "LOCUS"]],
                 fake_http.requests
  end

  def test_get_follows_redirects
    redirect = FakeHTTPRedirect.new("301", "Moved", "https://togows.org/entry/pubmed/1", "")
    first = FakeHTTP.new("togows.org", 80, redirect)
    second = FakeHTTP.new("togows.org", 443, FakeHTTPSuccess.new("ok"))
    calls = [first, second]
    client = TogoWS::Client.new("http://togows.org", 5)

    Net::HTTP.stub(:new, ->(_host, _port) { calls.shift }) do
      assert_equal "ok", client.get("/entry/pubmed/1")
    end

    refute first.use_ssl
    assert second.use_ssl
  end

  def test_http_error_is_raised_for_unsuccessful_response
    fake_http = FakeHTTP.new("togows.org", 80, FakeHTTPFailure.new("404", "Not Found", "missing"))
    client = TogoWS::Client.new("http://togows.org", 5)

    error = assert_raises(TogoWS::HTTPError) do
      Net::HTTP.stub(:new, fake_http) do
        client.get("/entry/pubmed/missing")
      end
    end

    assert_equal 404, error.code
    assert_equal "Not Found", error.message_text
    assert_equal "missing", error.body
  end
end
