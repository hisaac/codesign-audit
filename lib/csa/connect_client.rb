# frozen_string_literal: true

require 'spaceship'

module CSA
  class ConnectClient
    def initialize(config)
      @config = config
    end

    def fetch(included_assets:)
      return fetch_for_mode(in_house: true, included_assets: included_assets) if @config.in_house?

      fetch_for_mode(in_house: false, included_assets: included_assets)
    rescue StandardError
      fetch_for_mode(in_house: true, included_assets: included_assets)
    end

    private

    def fetch_for_mode(in_house:, included_assets:)
      token = Spaceship::ConnectAPI::Token.create(
        key_id: @config.api_key_id,
        issuer_id: @config.api_issuer_id,
        filepath: @config.api_key_file,
        key: @config.api_key_content,
        in_house: in_house
      )
      Spaceship::ConnectAPI.token = token

      certificates = if included_assets.nil? || included_assets.include?('certificates')
                       Spaceship::ConnectAPI::Certificate.all
                     else
                       []
                     end
      profiles = if included_assets.nil? || included_assets.include?('profiles')
                   Spaceship::ConnectAPI::Profile.all
                 else
                   []
                 end

      [certificates, profiles]
    end
  end
end
