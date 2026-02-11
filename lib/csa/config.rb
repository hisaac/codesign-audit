# frozen_string_literal: true

module CSA
  class Config
    STATUS_ALIASES = {
      'expired' => 'expired',
      'expiring' => 'expiring_soon',
      'expiring_soon' => 'expiring_soon',
      'invalid' => 'invalid',
      'ok' => 'ok'
    }.freeze
    VALID_STATUSES = %w[expired expiring_soon invalid ok].freeze
    VALID_TYPES = %w[development distribution].freeze
    VALID_ASSETS = %w[certificates profiles].freeze

    attr_reader :api_key_id, :api_issuer_id, :api_key_file, :api_key_content, :included_statuses, :included_types,
                :included_assets

    def initialize(options)
      @api_key_id = options[:api_key_id] || ENV.fetch('ASC_KEY_ID', nil)
      @api_issuer_id = options[:api_issuer_id] || ENV.fetch('ASC_ISSUER_ID', nil)
      explicit_api_key_file = resolve_explicit_api_key_file(options[:api_key_file])
      @api_key_file = resolve_api_key_file(explicit_api_key_file, @api_key_id, options[:api_key_stdin])
      @api_key_content = resolve_api_key_content(options[:api_key_stdin], explicit_api_key_file)
      @in_house = options[:in_house]
      @json = options[:json]
      @included_statuses = resolve_included_statuses(options[:include_statuses])
      @included_types = resolve_included_types(options[:include_types])
      @included_assets = resolve_included_assets(options[:include_assets])
    end

    def in_house?
      @in_house
    end

    def json?
      @json
    end

    private

    def resolve_explicit_api_key_file(provided_key_file)
      provided_key_file || ENV.fetch('ASC_KEY_FILE', nil)
    end

    def resolve_api_key_file(explicit_key_file, key_id, expect_stdin)
      return explicit_key_file if explicit_key_file
      return nil if expect_stdin

      candidate_key_file = key_id ? File.join(Dir.pwd, "AuthKey_#{key_id}.p8") : nil
      return candidate_key_file if candidate_key_file && File.file?(candidate_key_file)

      nil
    end

    def resolve_api_key_content(expect_stdin, explicit_api_key_file)
      return nil unless expect_stdin
      raise UserError, '--api-key-stdin cannot be used with --api-key-file or ASC_KEY_FILE' if explicit_api_key_file

      key_content = $stdin.read
      raise UserError, '--api-key-stdin was set, but stdin was empty' if key_content.strip.empty?

      key_content
    end

    def resolve_included_statuses(include_statuses_string)
      return nil unless include_statuses_string

      selected = include_statuses_string
                 .split(',')
                 .map { |value| value.strip.downcase }
                 .reject(&:empty?)
                 .map { |value| STATUS_ALIASES[value] || value }
                 .uniq

      invalid_statuses = selected - VALID_STATUSES
      return selected if invalid_statuses.empty?

      raise UserError,
            "Invalid include-statuses value(s): #{invalid_statuses.join(', ')}. Expected: #{VALID_STATUSES.join(', ')}"
    end

    def resolve_included_types(include_types_string)
      return nil unless include_types_string

      selected = include_types_string
                 .split(',')
                 .map { |value| value.strip.downcase }
                 .reject(&:empty?)
                 .uniq

      invalid_types = selected - VALID_TYPES
      return selected if invalid_types.empty?

      raise UserError,
            "Invalid include-types value(s): #{invalid_types.join(', ')}. Expected: #{VALID_TYPES.join(', ')}"
    end

    def resolve_included_assets(include_assets_string)
      return nil unless include_assets_string

      selected = include_assets_string
                 .split(',')
                 .map { |value| value.strip.downcase }
                 .reject(&:empty?)
                 .uniq

      invalid_assets = selected - VALID_ASSETS
      return selected if invalid_assets.empty?

      raise UserError,
            "Invalid include-assets value(s): #{invalid_assets.join(', ')}. Expected: #{VALID_ASSETS.join(', ')}"
    end
  end
end
