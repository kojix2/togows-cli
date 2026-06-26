# frozen_string_literal: true

require_relative "test_helper"

class TestColor < Minitest::Test
  class TTYOutput
    def tty?
      true
    end
  end

  class PlainOutput
    def tty?
      false
    end
  end

  def test_enabled_for_tty
    with_env("NO_COLOR" => nil) do
      refute TogoWS::Color.enabled_for?(PlainOutput.new)
      assert TogoWS::Color.enabled_for?(TTYOutput.new)
    end
  end

  def test_no_color_disables_color
    with_env("NO_COLOR" => "1") do
      refute TogoWS::Color.enabled_for?(TTYOutput.new)
    end
  end

  def test_apply_returns_plain_text_when_disabled
    color = TogoWS::Color.new(false)

    assert_equal "Usage:", color.bold("Usage:")
  end

  def test_apply_wraps_text_when_enabled
    color = TogoWS::Color.new(true)

    assert_equal "\e[1mUsage:\e[0m", color.bold("Usage:")
  end

  private

  def with_env(values)
    previous = values.keys.to_h { |key| [key, ENV.fetch(key, nil)] }
    values.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end
end
