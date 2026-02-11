# frozen_string_literal: true

require 'optparse'

module CSA
  class CLI
    VALID_COMMANDS = %w[list certificates profiles].freeze

    def self.run(argv = ARGV, out: $stdout, err: $stderr)
      new(argv: argv, out: out, err: err).run
    end

    def initialize(argv:, out:, err:)
      @argv = argv.dup
      @out = out
      @err = err
    end

    def run
      no_args = @argv.empty?
      parse_result = parse_args(@argv)
      return print_help(parse_result[:parser]) if no_args
      return print_help(parse_result[:parser]) if parse_result[:help]
      return print_version if parse_result[:version]

      config = Config.new(parse_result[:options])
      selected_asset = selected_asset_for(parse_result[:command])
      certificates, profiles = ConnectClient.new(config).fetch(selected_asset: selected_asset)
      certificate_rows = RecordNormalizer.normalize_all(certificates)
      profile_rows = RecordNormalizer.normalize_all(profiles)

      certificate_rows, profile_rows = Filtering.apply(
        certificate_rows: certificate_rows,
        profile_rows: profile_rows,
        selected_filters: config.selected_filters,
        exclude_development: config.exclude_development?
      )

      output =
        if config.json?
          Renderers::JsonRenderer.new(
            selected_asset: selected_asset,
            certificate_rows: certificate_rows,
            profile_rows: profile_rows
          ).render
        else
          Renderers::TableRenderer.new(
            selected_asset: selected_asset,
            certificate_rows: certificate_rows,
            profile_rows: profile_rows
          ).render
        end

      @out.puts(output)
      0
    rescue OptionParser::ParseError, UserError => e
      @err.puts(e.message)
      1
    end

    private

    def parse_args(argv)
      options = {}
      parser = OptionParser.new do |opts|
        opts.banner = <<~BANNER
          Usage:
            csa [list] [options]
            csa certificates [options]
            csa profiles [options]

          Commands:
            list          Show both certificates and profiles (default)
            certificates  Show only certificates
            profiles      Show only profiles

          Options:
        BANNER
        opts.on('--api-key-id KEY_ID') { |v| options[:api_key_id] = v }
        opts.on('--api-issuer-id ISSUER_ID') { |v| options[:api_issuer_id] = v }
        opts.on('--api-key-file PATH') { |v| options[:api_key_file] = v }
        opts.on('--api-key-stdin', 'Read ASC API key contents from stdin') { options[:api_key_stdin] = true }
        opts.on('--in-house') { options[:in_house] = true }
        opts.on('--json') { options[:json] = true }
        opts.on('--filter TYPES', 'Comma-separated filters: error,warn,ok') { |v| options[:filter] = v }
        opts.on('--exclude-development') { options[:exclude_development] = true }
        opts.on('-h', '--help') { options[:help] = true }
        opts.on('-v', '--version') { options[:version] = true }
      end

      parser.parse!(argv)

      command = resolve_command(argv.shift)
      raise UserError, "Unexpected argument(s): #{argv.join(' ')}" if argv.any?

      {
        options: options,
        command: command,
        help: options[:help],
        version: options[:version],
        parser: parser
      }
    end

    def resolve_command(raw_command)
      return 'list' if raw_command.nil?
      return raw_command if VALID_COMMANDS.include?(raw_command)

      raise UserError, "Invalid command '#{raw_command}'. Expected one of: #{VALID_COMMANDS.join(', ')}"
    end

    def selected_asset_for(command)
      case command
      when 'certificates'
        'certificates'
      when 'profiles'
        'profiles'
      end
    end

    def print_help(parser)
      @out.puts(parser)
      0
    end

    def print_version
      @out.puts(CSA::VERSION)
      0
    end
  end
end
