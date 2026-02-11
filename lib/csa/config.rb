# frozen_string_literal: true

module CSA
  class Config
    FILTER_ALIASES = {
      'error' => 'error',
      'errors' => 'error',
      'expired' => 'error',
      'warn' => 'warn',
      'warning' => 'warn',
      'warnings' => 'warn',
      'expiring_or_invalid' => 'warn',
      'ok' => 'ok',
      'fine' => 'ok',
      'good' => 'ok'
    }.freeze
    VALID_FILTERS = %w[error warn ok].freeze

    attr_reader :api_key_id, :api_issuer_id, :api_key_file, :api_key_content, :selected_filters

    def initialize(options)
      @api_key_id = options[:api_key_id] || ENV.fetch('ASC_KEY_ID', nil)
      @api_issuer_id = options[:api_issuer_id] || ENV.fetch('ASC_ISSUER_ID', nil)
      explicit_api_key_file = resolve_explicit_api_key_file(options[:api_key_file])
      @api_key_file = resolve_api_key_file(explicit_api_key_file, @api_key_id, options[:api_key_stdin])
      @api_key_content = resolve_api_key_content(options[:api_key_stdin], explicit_api_key_file)
      @in_house = options[:in_house]
      @json = options[:json]
      @exclude_development = options[:exclude_development]
      @selected_filters = resolve_selected_filters(options[:filter])
    end

    def in_house?
      @in_house
    end

    def json?
      @json
    end

    def exclude_development?
      @exclude_development
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

    def resolve_selected_filters(filter_string)
      return nil unless filter_string

      selected = filter_string
                 .split(',')
                 .map { |value| value.strip.downcase }
                 .reject(&:empty?)
                 .map { |value| FILTER_ALIASES[value] || value }
                 .uniq

      invalid_filters = selected - VALID_FILTERS
      return selected if invalid_filters.empty?

      raise UserError, "Invalid filter(s): #{invalid_filters.join(', ')}. Expected: #{VALID_FILTERS.join(', ')}"
    end
  end
end
