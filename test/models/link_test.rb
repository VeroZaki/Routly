# frozen_string_literal: true

require "test_helper"

class LinkTest < ActiveSupport::TestCase
  test "normalizes URL with protocol" do
    assert_equal "https://example.com", Link.normalize_url("https://example.com")
    assert_equal "http://example.com", Link.normalize_url("http://example.com")
  end

  test "adds https when no protocol" do
    assert_equal "https://example.com", Link.normalize_url("example.com")
    assert_equal "https://codesubmit.io/library/react", Link.normalize_url("codesubmit.io/library/react")
  end

  test "rejects blank or invalid URLs" do
    assert_nil Link.normalize_url("")
    assert_nil Link.normalize_url("   ")
    assert_nil Link.normalize_url("not a url at all")
  end

  test "extract_code from full URL" do
    assert_equal "GeAi9K", Link.extract_code("http://your.domain/GeAi9K")
    assert_equal "GeAi9K", Link.extract_code("https://localhost:3000/GeAi9K")
  end

  test "extract_code from path only" do
    assert_equal "GeAi9K", Link.extract_code("GeAi9K")
    assert_equal "GeAi9K", Link.extract_code("/GeAi9K")
  end

  test "extract_code ignores trailing path segments" do
    assert_equal "GeAi9K", Link.extract_code("http://localhost:3000/GeAi9K/extra")
    assert_equal "GeAi9K", Link.extract_code("/GeAi9K/extra")
  end

  test "extract_code returns nil for blank input" do
    assert_nil Link.extract_code(nil)
    assert_nil Link.extract_code("")
    assert_nil Link.extract_code("   ")
  end

  test "encode_url creates record and returns it" do
    record = Link.encode_url("https://example.com/one")
    assert record.persisted?
    assert record.original_url.present?
    assert record.code.present?
    assert_equal 6, record.code.length
  end

  test "encode_url is idempotent for the same normalized URL" do
    first = Link.encode_url("https://example.com/same")
    second = Link.encode_url("https://example.com/same")

    assert_equal first.id, second.id
    assert_equal first.code, second.code
    assert_equal 1, Link.where(original_url: "https://example.com/same").count
  end

  test "encode_url treats scheme-less and https forms as the same URL" do
    first = Link.encode_url("example.com/alias")
    second = Link.encode_url("https://example.com/alias")

    assert_equal first.id, second.id
    assert_equal "https://example.com/alias", first.original_url
  end

  test "encode_url generates distinct codes for different URLs" do
    first = Link.encode_url("https://example.com/a")
    second = Link.encode_url("https://example.com/b")

    assert_not_equal first.code, second.code
  end

  test "generated code is base62 and exact length" do
    record = Link.encode_url("https://example.com/code-format")
    assert_match(/\A[0-9A-Za-z]{6}\z/, record.code)
  end

  test "decode_to_original returns URL for existing code" do
    record = Link.encode_url("https://example.com/decode-me")
    short_url = "http://localhost/#{record.code}"
    assert_equal "https://example.com/decode-me", Link.decode_to_original(short_url)
  end

  test "decode_to_original accepts bare code" do
    record = Link.encode_url("https://example.com/bare-code")
    assert_equal "https://example.com/bare-code", Link.decode_to_original(record.code)
  end

  test "decode_to_original returns nil for unknown code" do
    assert_nil Link.decode_to_original("http://localhost/NoSuch")
  end

  test "decode_to_original returns nil for blank input" do
    assert_nil Link.decode_to_original(nil)
    assert_nil Link.decode_to_original("")
  end

  test "find_by_code! raises when missing" do
    assert_raises(ActiveRecord::RecordNotFound) { Link.find_by_code!("missing") }
  end

  test "find_by_code! finds existing record" do
    record = Link.encode_url("https://example.com/find-me")
    assert_equal record, Link.find_by_code!(record.code)
  end

  test "encode_url returns nil for invalid URL and does not persist" do
    record = Link.encode_url("javascript:alert(1)")
    assert_nil record
    assert_equal 0, Link.where(original_url: "javascript:alert(1)").count
  end

  test "validations prevent invalid URL from being saved" do
    record = Link.new(original_url: "not a url")
    assert_not record.save
    assert record.errors[:original_url].any?
  end

  test "encode_url returns nil when validation fails so controller can respond 422" do
    record = Link.encode_url("https://")
    assert_nil record
  end

  test "code must be base62 and exactly 6 characters" do
    record = Link.new(original_url: "https://example.com", code: "ab-cd")
    record.valid?
    assert_includes record.errors[:code], "must contain only letters and numbers (base62)"

    record.code = "abc"
    record.valid?
    assert_includes record.errors[:code], "must be 6 characters"
  end

  test "code uniqueness is enforced" do
    existing = Link.encode_url("https://example.com/unique-code")
    duplicate = Link.new(original_url: "https://example.com/other", code: existing.code)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:code], "has already been taken"
  end

  test "raises after too many code collisions" do
    Link.encode_url("https://example.com/collision-seed")

    Link.stub(:exists?, true) do
      error = assert_raises(RuntimeError) do
        Link.encode_url("https://example.com/collision-fail")
      end
      assert_match(/collision after #{Link::MAX_COLLISION_RETRIES} retries/, error.message)
    end
  end
end
