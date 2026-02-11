# frozen_string_literal: true

require 'json'

module CSA
  module Renderers
    class JsonRenderer
      def initialize(included_assets:, certificate_rows:, profile_rows:)
        @included_assets = included_assets
        @certificate_rows = certificate_rows
        @profile_rows = profile_rows
      end

      def render
        payload = {}
        payload[:certificates] = @certificate_rows if include_certificates?
        payload[:profiles] = @profile_rows if include_profiles?
        JSON.pretty_generate(payload)
      end

      private

      def include_certificates?
        @included_assets.nil? || @included_assets.include?('certificates')
      end

      def include_profiles?
        @included_assets.nil? || @included_assets.include?('profiles')
      end
    end
  end
end
