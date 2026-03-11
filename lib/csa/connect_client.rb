# frozen_string_literal: true

require 'json'
require 'net/http'
require 'spaceship'

module CSA
  class ConnectClient
    CERTIFICATES_PAGE_LIMIT = 200

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
      token = build_token(in_house: in_house)
      Spaceship::ConnectAPI.token = token

      certificates = if included_assets.nil? || included_assets.include?('certificates')
                       fetch_certificates(token)
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

    def build_token(in_house:)
      Spaceship::ConnectAPI::Token.create(
        key_id: @config.api_key_id,
        issuer_id: @config.api_issuer_id,
        filepath: @config.api_key_file,
        key: @config.api_key_content,
        in_house: in_house
      )
    end

    def fetch_certificates(token)
      next_url = "#{base_url(token)}/v1/certificates?limit=#{CERTIFICATES_PAGE_LIMIT}"
      certificates = []

      while next_url
        payload = get_json(next_url, token)
        certificates.concat(payload.fetch('data', []).map { |item| normalize_certificate(item) })
        next_url = payload.fetch('links', {})['next']
      end

      certificates
    end

    def base_url(token)
      token.in_house ? 'https://api.enterprise.developer.apple.com' : 'https://api.appstoreconnect.apple.com'
    end

    def get_json(url, token)
      uri = URI(url)
      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{token.text}"
      request['Content-Type'] = 'application/json'

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      parsed_body = response.body.to_s.empty? ? {} : JSON.parse(response.body)
      return parsed_body if response.is_a?(Net::HTTPSuccess)

      message =
        if parsed_body['errors']
          parsed_body['errors'].map { |error| error['detail'] || error['title'] || error['code'] }.compact.join('; ')
        else
          response.body.to_s
        end

      raise "Certificate API request failed (#{response.code}): #{message}"
    end

    def normalize_certificate(item)
      attributes = item.fetch('attributes', {}).each_with_object({}) do |(key, value), normalized|
        normalized[underscore(key)] = value
      end

      attributes['id'] = item['id'] if item['id']
      attributes
    end

    def underscore(value)
      value.to_s
           .gsub(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
           .gsub(/([a-z\d])([A-Z])/, '\1_\2')
           .tr('-', '_')
           .downcase
    end
  end
end
