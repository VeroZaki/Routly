class UrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    normalized = UrlNormalizer.normalize(value)
    return if normalized.present?

    record.errors.add(attribute, options[:message] || "is not a valid URL")
  end
end
