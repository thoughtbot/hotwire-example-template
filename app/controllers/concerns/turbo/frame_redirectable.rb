module Turbo
  module FrameRedirectable
    extend ActiveSupport::Concern

    included do
      around_action :transform_turbo_frame_param_into_header

      def redirect_to(options = {}, response_options = {})
        turbo_frame = response_options.delete(:turbo_frame) { headers["Turbo-Frame"] }

        super

        if turbo_frame.present?
          location_uri = URI(location)
          location_params = Rack::Utils.parse_query(location_uri.query)
          location_params.reverse_merge! _turbo_frame: turbo_frame
          location_uri.query = location_params.to_query

          self.location = location_uri.to_s
        end
      end
    end

    private

    def transform_turbo_frame_param_into_header
      turbo_frame = params.delete(:_turbo_frame)

      yield

      headers["Turbo-Frame"] = turbo_frame.presence
    end
  end
end
