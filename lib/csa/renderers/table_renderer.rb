# frozen_string_literal: true

require 'terminal-table'

module CSA
  module Renderers
    class TableRenderer
      ANSI_RED = "\e[31m"
      ANSI_YELLOW = "\e[33m"
      ANSI_RESET = "\e[0m"
      HUMAN_DATE_FORMAT = '%b %-d, %Y'
      DATE_FIELDS = %w[created_date expiration_date].freeze
      CERTIFICATE_HEADINGS = %w[display_name type platform expiration_date days_until_expiration].freeze
      PROFILE_HEADINGS = %w[name profile_type platform profile_state expiration_date days_until_expiration].freeze

      def initialize(included_assets:, certificate_rows:, profile_rows:)
        @included_assets = included_assets
        @certificate_rows = certificate_rows
        @profile_rows = profile_rows
      end

      def render
        sections = []
        sections << certificate_table if include_certificates?
        sections << profile_table if include_profiles?
        sections.compact.join("\n\n")
      end

      private

      def include_certificates?
        @included_assets.nil? || @included_assets.include?('certificates')
      end

      def include_profiles?
        @included_assets.nil? || @included_assets.include?('profiles')
      end

      def format_rows(rows)
        rows.map do |row|
          row.each_with_object({}) do |(key, value), memo|
            memo[key] = TimeUtils.to_human_date(value, date_fields: DATE_FIELDS, key: key, format: HUMAN_DATE_FORMAT)
          end
        end
      end

      def certificate_table
        sorted_rows = @certificate_rows.sort_by { |row| TimeUtils.sort_key_by_expiration(row) }
        table_rows = format_rows(sorted_rows)

        Terminal::Table.new(
          title: 'Certificates',
          headings: CERTIFICATE_HEADINGS,
          rows: table_rows.each_with_index.map do |row, index|
            values = CERTIFICATE_HEADINGS.map do |key|
              case key
              when 'days_until_expiration'
                TimeUtils.days_until_expiration(sorted_rows[index])
              when 'type'
                certificate_name_prefix(sorted_rows[index])
              else
                row[key]
              end
            end
            colorize_row_values(values, row_color(sorted_rows[index]))
          end
        ).to_s
      end

      def profile_table
        table_rows = format_rows(@profile_rows)
        profile_state_index = PROFILE_HEADINGS.index('profile_state')

        Terminal::Table.new(
          title: 'Profiles',
          headings: PROFILE_HEADINGS,
          rows: table_rows.each_with_index.map do |row, index|
            values = PROFILE_HEADINGS.map do |key|
              key == 'days_until_expiration' ? TimeUtils.days_until_expiration(@profile_rows[index]) : row[key]
            end

            colored_values = colorize_row_values(values, row_color(@profile_rows[index]))
            if @profile_rows[index]['profile_state'].to_s == 'INVALID' && profile_state_index
              raw_state = row['profile_state']
              colored_values[profile_state_index] = raw_state.nil? ? nil : "#{ANSI_RED}#{raw_state}#{ANSI_RESET}"
            end
            colored_values
          end
        ).to_s
      end

      def row_color(row)
        return ANSI_RED if TimeUtils.expired?(row)
        return ANSI_YELLOW if TimeUtils.expiring_soon?(row, window_days: 30)

        nil
      end

      def certificate_name_prefix(row)
        name = row['name'].to_s
        display_name = row['display_name'].to_s
        return nil if name.empty?

        if !display_name.empty? && name.end_with?(display_name)
          prefix = name[0, name.length - display_name.length].sub(/[\s:-]+$/, '')
          return prefix unless prefix.empty?
        end

        name.split(/[:-]/, 2).first.to_s.strip
      end

      def colorize_row_values(values, color)
        return values unless color

        values.map { |value| value.nil? ? nil : "#{color}#{value}#{ANSI_RESET}" }
      end
    end
  end
end
