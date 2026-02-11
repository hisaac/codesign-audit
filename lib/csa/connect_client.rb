# frozen_string_literal: true

require 'spaceship'

module CSA
  class ConnectClient
    def initialize(config)
      @config = config
    end

    def fetch(selected_asset:)
      return fetch_for_mode(in_house: true, selected_asset: selected_asset) if @config.in_house?

      fetch_for_mode(in_house: false, selected_asset: selected_asset)
    rescue StandardError
      fetch_for_mode(in_house: true, selected_asset: selected_asset)
    end

    private

    def fetch_for_mode(in_house:, selected_asset:)
      token = Spaceship::ConnectAPI::Token.create(
        key_id: @config.api_key_id,
        issuer_id: @config.api_issuer_id,
        filepath: @config.api_key_file,
        key: @config.api_key_content,
        in_house: in_house
      )
      Spaceship::ConnectAPI.token = token

      certificates = if selected_asset.nil? || selected_asset == 'certificates'
                       Spaceship::ConnectAPI::Certificate.all
                     else
                       []
                     end
      profiles = if selected_asset.nil? || selected_asset == 'profiles'
                   Spaceship::ConnectAPI::Profile.all
                 else
                   []
                 end

      [certificates, profiles]
    end
  end
end
