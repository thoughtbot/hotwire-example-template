ActiveSupport.on_load :action_controller_base do
  include Pagy::Backend
end

ActiveSupport.on_load :action_view do
  include Pagy::UrlHelpers
end
