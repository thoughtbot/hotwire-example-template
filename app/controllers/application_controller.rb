class ApplicationController < ActionController::Base
  before_action :authenticate!

  private def authenticate!
    if (id = session[:user_id])
      Current.user = User.find id
    else
      redirect_to new_session_path
    end
  end
end
