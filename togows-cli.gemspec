# frozen_string_literal: true

require_relative "lib/togows/version"

Gem::Specification.new do |spec|
  spec.name = "togows-cli"
  spec.version = TogoWS::VERSION
  spec.authors = ["kojix2"]
  spec.email = ["2xijok@gmail.com"]

  spec.summary = "Dependency-free command line client for the TogoWS REST API"
  spec.description = "togows-cli provides a small Ruby command line interface for TogoWS entry, search, " \
                     "convert, and UCSC API endpoints."
  spec.homepage = "https://github.com/kojix2/togows-cli"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "#{spec.homepage}/tree/main",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir.chdir(__dir__) do
    Dir.glob(
      %w[
        LICENSE.txt
        README.md
        exe/*
        lib/**/*.rb
      ]
    )
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |file| File.basename(file) }
  spec.require_paths = ["lib"]
end
