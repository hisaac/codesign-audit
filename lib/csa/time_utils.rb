# frozen_string_literal: true

require 'date'
require 'time'

module CSA
  module TimeUtils
    module_function

    def parse_datetime(value)
      case value
      when Time
        value
      when DateTime, Date
        value.to_time
      when String
        parse_string_datetime(value)
      end
    end

    def days_until_expiration(row)
      expiration = parse_datetime(row['expiration_date'])
      return nil unless expiration

      (expiration.getutc.to_date - Time.now.getutc.to_date).to_i
    end

    def sort_key_by_expiration(row)
      parsed = parse_datetime(row['expiration_date'])
      parsed ? [0, parsed.to_i] : [1, Float::INFINITY]
    end

    def expiring_soon?(row, window_days: 30)
      expiration = parse_datetime(row['expiration_date'])
      return false unless expiration

      expiration <= Time.now + (window_days * 24 * 60 * 60)
    end

    def expired?(row)
      expiration = parse_datetime(row['expiration_date'])
      expiration && expiration < Time.now
    end

    def to_human_date(value, date_fields:, key: nil, format: '%b %-d, %Y')
      case value
      when Time
        value.getutc.strftime(format)
      when DateTime
        value.to_time.getutc.strftime(format)
      when Date
        value.strftime(format)
      when String
        parsed_time = date_fields.include?(key.to_s) ? parse_string_datetime(value) : nil
        parsed_time ? parsed_time.getutc.strftime(format) : value
      when Array
        value.map { |item| to_human_date(item, date_fields: date_fields, key: key, format: format) }
      when Hash
        value.each_with_object({}) do |(child_key, child_value), memo|
          memo[child_key] = to_human_date(child_value, date_fields: date_fields, key: child_key, format: format)
        end
      else
        value
      end
    end

    def parse_string_datetime(value)
      Time.iso8601(value)
    rescue ArgumentError
      Time.parse(value)
    rescue StandardError
      nil
    end
  end
end
