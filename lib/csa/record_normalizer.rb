# frozen_string_literal: true

module CSA
  module RecordNormalizer
    module_function

    REDACTED_FIELDS = %w[certificate_content profile_content].freeze

    def normalize_all(records)
      records.map { |record| normalize(record) }
    end

    def normalize(record)
      return nil unless record

      data = if record.is_a?(Hash)
               record.dup
             else
               record.instance_variables.each_with_object({}) do |ivar, hash|
                 key = ivar.to_s.delete_prefix('@')
                 hash[key] = record.instance_variable_get(ivar)
               end
             end

      REDACTED_FIELDS.each { |field| data.delete(field) }
      data
    end
  end
end
