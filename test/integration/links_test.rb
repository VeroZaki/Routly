# frozen_string_literal: true

require "test_helper"

class LinksIntegrationTest < ActionDispatch::IntegrationTest
  def test_encode_returns_short_url_as_json
    post "/encode", params: { url: "https://codesubmit.io/library/react" }, as: :json
    assert_response :created
    json = response.parsed_body
    assert json["short_url"].present?
    assert_match %r{/[\w]{6}\z}, json["short_url"]
    assert_equal "https://codesubmit.io/library/react", json["original_url"]
  end

  def test_encode_normalizes_url_without_scheme
    post "/encode", params: { url: "example.com/no-scheme" }, as: :json
    assert_response :created
    assert_equal "https://example.com/no-scheme", response.parsed_body["original_url"]
  end

  def test_encode_idempotent_same_url_returns_same_short_url
    post "/encode", params: { url: "https://example.com/page" }, as: :json
    assert_response :created
    first_short = response.parsed_body["short_url"]

    post "/encode", params: { url: "https://example.com/page" }, as: :json
    assert_response :created
    second_short = response.parsed_body["short_url"]

    assert_equal first_short, second_short
  end

  def test_encode_uses_routly_base_url_env
    previous = ENV["ROUTLY_BASE_URL"]
    ENV["ROUTLY_BASE_URL"] = "https://go.routly.test"

    post "/encode", params: { url: "https://example.com/custom-base" }, as: :json
    assert_response :created
    assert_match %r{\Ahttps://go\.routly\.test/[0-9A-Za-z]{6}\z}, response.parsed_body["short_url"]
  ensure
    if previous
      ENV["ROUTLY_BASE_URL"] = previous
    else
      ENV.delete("ROUTLY_BASE_URL")
    end
  end

  def test_encode_with_invalid_url_returns_422
    post "/encode", params: { url: "not a url at all" }, as: :json
    assert_response :unprocessable_entity
    json = response.parsed_body
    assert_equal "Invalid URL", json["error"]
  end

  def test_encode_rejects_javascript_url
    post "/encode", params: { url: "javascript:alert(1)" }, as: :json
    assert_response :unprocessable_entity
    assert_equal "Invalid URL", response.parsed_body["error"]
  end

  def test_encode_rejects_data_url
    post "/encode", params: { url: "data:text/html,hi" }, as: :json
    assert_response :unprocessable_entity
  end

  def test_encode_without_url_param_returns_400
    post "/encode", params: {}, as: :json
    assert_response :bad_request
    assert_equal "Missing parameter: url", response.parsed_body["error"]
  end

  def test_encode_with_blank_url_returns_400
    post "/encode", params: { url: "   " }, as: :json
    assert_response :bad_request
    assert_equal "Missing parameter: url", response.parsed_body["error"]
  end

  def test_decode_returns_original_url_as_json
    post "/encode", params: { url: "https://codesubmit.io/library/react" }, as: :json
    short_url = response.parsed_body["short_url"]

    post "/decode", params: { short_url: short_url }, as: :json
    assert_response :ok
    json = response.parsed_body
    assert_equal "https://codesubmit.io/library/react", json["original_url"]
  end

  def test_decode_accepts_bare_code
    post "/encode", params: { url: "https://example.com/bare" }, as: :json
    code = response.parsed_body["short_url"].split("/").last

    post "/decode", params: { short_url: code }, as: :json
    assert_response :ok
    assert_equal "https://example.com/bare", response.parsed_body["original_url"]
  end

  def test_decode_with_unknown_short_url_returns_404
    post "/decode", params: { short_url: "http://localhost:3000/Unknown" }, as: :json
    assert_response :not_found
    assert_equal "Short URL not found or invalid", response.parsed_body["error"]
  end

  def test_decode_without_short_url_param_returns_400
    post "/decode", params: {}, as: :json
    assert_response :bad_request
    assert_equal "Missing parameter: short_url", response.parsed_body["error"]
  end

  def test_decode_with_blank_short_url_returns_400
    post "/decode", params: { short_url: "  " }, as: :json
    assert_response :bad_request
    assert_equal "Missing parameter: short_url", response.parsed_body["error"]
  end

  def test_encode_then_decode_round_trip_for_multiple_urls
    urls = [
      "https://example.com/one",
      "https://example.com/two?q=1",
      "http://example.org/path"
    ]

    urls.each do |url|
      post "/encode", params: { url: url }, as: :json
      assert_response :created
      short_url = response.parsed_body["short_url"]

      post "/decode", params: { short_url: short_url }, as: :json
      assert_response :ok
      assert_equal url, response.parsed_body["original_url"]
    end
  end

  def test_encoded_url_survives_restart
    post "/encode", params: { url: "https://example.com/persistent" }, as: :json
    assert_response :created
    short_url = response.parsed_body["short_url"]

    post "/decode", params: { short_url: short_url }, as: :json
    assert_response :ok
    assert_equal "https://example.com/persistent", response.parsed_body["original_url"]
  end

  def test_unknown_route_is_not_found
    get "/"
    assert_response :not_found
  end
end
