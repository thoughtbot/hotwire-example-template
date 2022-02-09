module Turbo
  module FrameRedirectable
    extend ActiveSupport::Concern

    included do
      before_action :transform_turbo_frame_flash_into_header

      def redirect_to(options = {}, response_options = {})
        turbo_frame = response_options.delete(:turbo_frame) { request.headers["Turbo-Frame"] }

        super

        flash["Turbo-Frame"] = response.headers["Turbo-Frame"] = turbo_frame
      end

      private

      def transform_turbo_frame_flash_into_header
        response.headers["Turbo-Frame"] = flash["Turbo-Frame"]

        flash.delete "Turbo-Frame"
      end
    end
  end
end
