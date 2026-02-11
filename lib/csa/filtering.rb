# frozen_string_literal: true

module CSA
  module Filtering
    module_function

    def apply(certificate_rows:, profile_rows:, included_statuses:, included_types:, included_assets:)
      filter_by_asset!(certificate_rows, profile_rows, included_assets)
      filter_by_status!(certificate_rows, included_statuses)
      filter_by_status!(profile_rows, included_statuses)

      filter_by_type!(certificate_rows, included_types)
      filter_by_type!(profile_rows, included_types)

      profile_rows.sort_by! { |row| TimeUtils.sort_key_by_expiration(row) }

      [certificate_rows, profile_rows]
    end

    def filter_by_asset!(certificate_rows, profile_rows, included_assets)
      return unless included_assets

      certificate_rows.clear unless included_assets.include?('certificates')
      profile_rows.clear unless included_assets.include?('profiles')
    end

    def statuses_for(row)
      invalid_state = row['profile_state'].to_s == 'INVALID'
      expired = TimeUtils.expired?(row)
      expiring_soon = !expired && TimeUtils.expiring_soon?(row, window_days: 30)
      statuses = []

      statuses << 'expired' if expired
      statuses << 'expiring_soon' if expiring_soon
      statuses << 'invalid' if invalid_state
      statuses << 'ok' if statuses.empty?
      statuses
    end

    def filter_by_status!(rows, included_statuses)
      return unless included_statuses

      rows.select! { |row| statuses_for(row).intersect?(included_statuses) }
    end

    def filter_by_type!(rows, included_types)
      return unless included_types

      rows.select! { |row| included_types.include?(type_for(row)) }
    end

    def type_for(row)
      type_value = row['certificate_type'] || row['profile_type']
      return 'development' if type_value.to_s.match?(/development/i)

      'distribution'
    end
  end
end
