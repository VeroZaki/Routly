class Base62Validator < ActiveModel::EachValidator
  BASE62_PATTERN = /\A[0-9A-Za-z]+\z/

  def validate_each(record, attribute, value)
    return if value.blank?

    unless value.to_s.match?(BASE62_PATTERN)
      record.errors.add(attribute, options[:message] || "must contain only letters and numbers (base62)")
      return
    end

    if options[:length].present?
      unless value.to_s.length == options[:length]
        record.errors.add(attribute, "must be #{options[:length]} characters")
      end
    end

    if options[:length_range].present?
      range = options[:length_range]
      len = value.to_s.length
      unless range.cover?(len)
        record.errors.add(attribute, "must be between #{range.min} and #{range.max} characters")
      end
    end
  end
end
