# frozen_string_literal: true

module TogoWS
  class Color
    STYLES = {
      bold: 1
    }.freeze

    def initialize(enabled)
      @enabled = enabled
    end

    def self.enabled_for?(io)
      io.respond_to?(:tty?) && io.tty? && !ENV.key?("NO_COLOR")
    end

    def apply(text, *styles)
      return text unless @enabled

      codes = styles.map { |style| STYLES.fetch(style) }
      "\e[#{codes.join(';')}m#{text}\e[0m"
    end

    def bold(text)
      apply(text, :bold)
    end
  end
end
