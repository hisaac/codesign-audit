# frozen_string_literal: true

module CSA
  module Filtering
    module_function

    def apply(certificate_rows:, profile_rows:, selected_filters:, exclude_development:)
      filter_by_status!(certificate_rows, selected_filters)
      filter_by_status!(profile_rows, selected_filters)

      if exclude_development
        certificate_rows.reject! { |row| row['certificate_type'].to_s.match?(/development/i) }
        profile_rows.reject! { |row| row['profile_type'].to_s.match?(/development/i) }
      end

      profile_rows.sort_by! { |row| TimeUtils.sort_key_by_expiration(row) }

      [certificate_rows, profile_rows]
    end

    def status_for(row)
      invalid_state = row['profile_state'].to_s == 'INVALID'

      if TimeUtils.expired?(row)
        'error'
      elsif invalid_state || TimeUtils.expiring_soon?(row, window_days: 30)
        'warn'
      else
        'ok'
      end
    end

    def filter_by_status!(rows, selected_filters)
      return unless selected_filters

      rows.select! { |row| selected_filters.include?(status_for(row)) }
    end
  end
end
