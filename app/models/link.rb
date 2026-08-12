# frozen_string_literal: true

class Link < ApplicationRecord
  # Base62 alphabet (0-9, A-Z, a-z) for short codes
  BASE62 = ("0".."9").to_a + ("A".."Z").to_a + ("a".."z").to_a
  CODE_LENGTH = 6
  MAX_COLLISION_RETRIES = 5

  validates :original_url, presence: true, url: true
  validates :code, presence: true, uniqueness: true, base62: { length: CODE_LENGTH }

  before_validation :normalize_original_url, on: :create
  before_validation :generate_code, on: :create, if: -> { code.blank? }

  def self.find_by_code!(code)
    find_by!(code: code)
  end

  def self.encode_url(original_url)
    normalized = UrlNormalizer.normalize(original_url)
    return nil if normalized.blank?

    existing = find_by(original_url: normalized)
    return existing if existing

    record = new(original_url: normalized)
    record.save ? record : nil
  end

  def self.decode_to_original(short_url)
    code = extract_code(short_url)
    return nil if code.blank?

    record = find_by(code: code)
    record&.original_url
  end

  def self.normalize_url(url)
    UrlNormalizer.normalize(url)
  end

  def self.extract_code(short_url)
    return nil if short_url.blank?

    path = short_url.to_s.strip
    path = URI.parse(path).path if path.match?(%r{\Ahttps?://})
    path = path.delete_prefix("/").split("/").first
    path.presence
  end

  private

  def normalize_original_url
    self.original_url = UrlNormalizer.normalize(original_url)
  end

  def generate_code
    retries = 0
    loop do
      self.code = generate_random_code
      break unless Link.exists?(code: code)

      retries += 1
      raise "Short code collision after #{MAX_COLLISION_RETRIES} retries" if retries >= MAX_COLLISION_RETRIES
    end
  end

  def generate_random_code
    CODE_LENGTH.times.map { BASE62.sample }.join
  end
end
