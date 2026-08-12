module UrlNormalizer
  class << self
    def normalize(url)
      return nil if url.blank?

      url = url.to_s.strip
      return nil if url.match?(/\A\s*javascript:/i) || url.match?(/\A\s*data:/i)
      url = "https://#{url}" unless url.match?(%r{\Ahttps?://}i)
      return nil unless url.match?(%r{\Ahttps?://[^\s]+\z}i)

      parsed = URI.parse(url)
      return nil unless parsed.is_a?(URI::HTTP) && parsed.host.present? && !parsed.host.start_with?("javascript", "data")

      url
    rescue URI::InvalidURIError
      nil
    end
  end
end
