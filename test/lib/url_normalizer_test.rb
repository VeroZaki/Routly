# frozen_string_literal: true

require "test_helper"

class UrlNormalizerTest < ActiveSupport::TestCase
  test "keeps http and https urls" do
    assert_equal "https://example.com/path", UrlNormalizer.normalize("https://example.com/path")
    assert_equal "http://example.com", UrlNormalizer.normalize("http://example.com")
  end

  test "strips surrounding whitespace" do
    assert_equal "https://example.com", UrlNormalizer.normalize("  https://example.com  ")
  end

  test "adds https when scheme is missing" do
    assert_equal "https://example.com/a", UrlNormalizer.normalize("example.com/a")
  end

  test "rejects blank values" do
    assert_nil UrlNormalizer.normalize(nil)
    assert_nil UrlNormalizer.normalize("")
    assert_nil UrlNormalizer.normalize("   ")
  end

  test "rejects javascript and data schemes" do
    assert_nil UrlNormalizer.normalize("javascript:alert(1)")
    assert_nil UrlNormalizer.normalize("JAVASCRIPT:alert(1)")
    assert_nil UrlNormalizer.normalize("data:text/html,hi")
  end

  test "rejects urls with spaces" do
    assert_nil UrlNormalizer.normalize("https://example.com/has space")
    assert_nil UrlNormalizer.normalize("not a url at all")
  end

  test "rejects incomplete urls" do
    assert_nil UrlNormalizer.normalize("https://")
    assert_nil UrlNormalizer.normalize("http://")
  end
end
