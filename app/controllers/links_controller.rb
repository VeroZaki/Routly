# frozen_string_literal: true

class LinksController < ApplicationController
  def encode
    url = params[:url].presence
    unless url
      return render json: { error: "Missing parameter: url" }, status: :bad_request
    end

    record = Link.encode_url(url)
    unless record
      return render json: { error: "Invalid URL" }, status: :unprocessable_entity
    end

    short_url = build_short_url(record.code)
    render json: { short_url: short_url, original_url: record.original_url }, status: :created
  rescue RuntimeError => e
    if e.message.include?("collision")
      render json: { error: "Unable to generate short URL. Please try again." }, status: :service_unavailable
    else
      raise
    end
  end

  def decode
    short_url_param = params[:short_url].presence
    unless short_url_param
      return render json: { error: "Missing parameter: short_url" }, status: :bad_request
    end

    original_url = Link.decode_to_original(short_url_param)
    unless original_url
      return render json: { error: "Short URL not found or invalid" }, status: :not_found
    end

    render json: { original_url: original_url }
  end

  private

  def build_short_url(code)
    base = ENV.fetch("ROUTLY_BASE_URL", "http://localhost:3000")
    base = base.chomp("/")
    "#{base}/#{code}"
  end
end
