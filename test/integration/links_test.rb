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

  def test_encode_idempotent_same_url_returns_same_short_url
    post "/encode", params: { url: "https://example.com/page" }, as: :json
    assert_response :created
    first_short = response.parsed_body["short_url"]

    post "/encode", params: { url: "https://example.com/page" }, as: :json
    assert_response :created
    second_short = response.parsed_body["short_url"]

    assert_equal first_short, second_short
  end

  def test_encode_with_invalid_url_returns_422
    post "/encode", params: { url: "not-a-url" }, as: :json
    assert_response :unprocessable_entity
    json = response.parsed_body
    assert json["error"].present?
  end

  def test_encode_without_url_param_returns_400
    post "/encode", params: {}, as: :json
    assert_response :bad_request
    assert response.parsed_body["error"].present?
  end

  def test_decode_returns_original_url_as_json
    post "/encode", params: { url: "https://codesubmit.io/library/react" }, as: :json
    short_url = response.parsed_body["short_url"]

    post "/decode", params: { short_url: short_url }, as: :json
    assert_response :ok
    json = response.parsed_body
    assert_equal "https://codesubmit.io/library/react", json["original_url"]
  end

  def test_decode_with_unknown_short_url_returns_404
    post "/decode", params: { short_url: "http://localhost:3000/Unknown" }, as: :json
    assert_response :not_found
    assert response.parsed_body["error"].present?
  end

  def test_decode_without_short_url_param_returns_400
    post "/decode", params: {}, as: :json
    assert_response :bad_request
    assert response.parsed_body["error"].present?
  end

  def test_encoded_url_survives_restart
    post "/encode", params: { url: "https://example.com/persistent" }, as: :json
    assert_response :created
    short_url = response.parsed_body["short_url"]

    post "/decode", params: { short_url: short_url }, as: :json
    assert_response :ok
    assert_equal "https://example.com/persistent", response.parsed_body["original_url"]
  end
end
