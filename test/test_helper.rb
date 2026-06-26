# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "stringio"
require "togows"

module StubHelper
  def stub_method(receiver, name, replacement)
    singleton_class = receiver.singleton_class
    had_singleton_method = singleton_class.method_defined?(name) || singleton_class.private_method_defined?(name)
    original = receiver.method(name) if receiver.respond_to?(name, true)

    without_redefinition_warnings do
      receiver.define_singleton_method(name) do |*args, **kwargs, &block|
        if replacement.respond_to?(:call)
          replacement.call(*args, **kwargs, &block)
        else
          replacement
        end
      end
    end

    yield
  ensure
    without_redefinition_warnings do
      singleton_class.remove_method(name)

      if had_singleton_method
        receiver.define_singleton_method(name) do |*args, **kwargs, &block|
          original.call(*args, **kwargs, &block)
        end
      end
    end
  end

  def without_redefinition_warnings
    previous_verbose = $VERBOSE
    $VERBOSE = nil
    yield
  ensure
    $VERBOSE = previous_verbose
  end
end

module Minitest
  class Test
    include StubHelper
  end
end
