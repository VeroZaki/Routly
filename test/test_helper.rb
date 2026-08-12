# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/rails"

module ActiveSupport
  class TestCase
    self.use_transactional_tests = true
  end
end
