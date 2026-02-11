# frozen_string_literal: true

require 'json'

module CSA
  module Renderers
    class JsonRenderer
      def initialize(selected_asset:, certificate_rows:, profile_rows:)
        @selected_asset = selected_asset
        @certificate_rows = certificate_rows
        @profile_rows = profile_rows
      end

      def render
        payload = {}
        payload[:certificates] = @certificate_rows if @selected_asset.nil? || @selected_asset == 'certificates'
        payload[:profiles] = @profile_rows if @selected_asset.nil? || @selected_asset == 'profiles'
        JSON.pretty_generate(payload)
      end
    end
  end
end
