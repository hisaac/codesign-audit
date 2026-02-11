# frozen_string_literal: true

require 'optparse'

module CSA
  class CLI
    def self.run(argv = ARGV, out: $stdout, err: $stderr)
      new(argv: argv, out: out, err: err).run
    end

    def initialize(argv:, out:, err:)
      @argv = argv.dup
      @out = out
      @err = err
    end

    def run
      parse_result = parse_args(@argv)
      return print_help(parse_result[:parser]) if parse_result[:help]
      return print_version if parse_result[:version]

      config = Config.new(parse_result[:options])
      certificates, profiles = ConnectClient.new(config).fetch(included_assets: config.included_assets)
      certificate_rows = RecordNormalizer.normalize_all(certificates)
      profile_rows = RecordNormalizer.normalize_all(profiles)

      certificate_rows, profile_rows = Filtering.apply(
        certificate_rows: certificate_rows,
        profile_rows: profile_rows,
        included_statuses: config.included_statuses,
        included_types: config.included_types,
        included_assets: config.included_assets
      )

      output =
        if config.json?
          Renderers::JsonRenderer.new(
            included_assets: config.included_assets,
            certificate_rows: certificate_rows,
            profile_rows: profile_rows
          ).render
        else
          Renderers::TableRenderer.new(
            included_assets: config.included_assets,
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
            csa [options]

          Description:
            Uses the App Store Connect API or Apple Enterprise API to fetch and display information
            about certificates and provisioning profiles associated with an Apple Developer account.

          Environment:
            ASC_KEY_ID         Fallback for --api-key-id
            ASC_ISSUER_ID      Fallback for --api-issuer-id
            ASC_KEY_FILE       Fallback for --api-key-file

          Default include behavior:
            If an include flag is omitted, all values for that dimension are included.

          Options:
        BANNER
        opts.separator ''
        opts.separator '  Authentication:'
        opts.on('--api-key-id KEY_ID', 'App Store Connect key id (env: ASC_KEY_ID)') do |v|
          options[:api_key_id] = v
        end
        opts.on('--api-issuer-id ISSUER_ID', 'App Store Connect issuer id (env: ASC_ISSUER_ID)') do |v|
          options[:api_issuer_id] = v
        end
        opts.on('--api-key-file PATH', 'Path to API key file (env: ASC_KEY_FILE)') do |v|
          options[:api_key_file] = v
        end
        opts.on('--api-key-stdin', 'Read ASC API key contents from stdin') { options[:api_key_stdin] = true }
        opts.separator ''
        opts.separator '  API Mode:'
        opts.on('--enterprise', 'Force Apple Enterprise API mode (skip App Store Connect first attempt)') do
          options[:in_house] = true
        end
        opts.separator ''
        opts.separator '  Output:'
        opts.on('--json', 'Output JSON instead of formatted tables') { options[:json] = true }
        opts.on('--include-statuses STATUSES',
                'Comma-separated statuses to include in output: expired,expiring_soon,invalid,ok') do |v|
          options[:include_statuses] = v
        end
        opts.on('--include-types TYPES', 'Comma-separated types to include in output: development,distribution') do |v|
          options[:include_types] = v
        end
        opts.on('--include-assets ASSETS', 'Comma-separated assets to include in output: certificates,profiles') do |v|
          options[:include_assets] = v
        end
        opts.separator ''
        opts.separator '  Misc:'
        opts.on('-h', '--help') { options[:help] = true }
        opts.on('-v', '--version') { options[:version] = true }
      end

      parser.parse!(argv)
      raise UserError, "Unexpected argument(s): #{argv.join(' ')}" if argv.any?

      {
        options: options,
        help: options[:help],
        version: options[:version],
        parser: parser
      }
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
