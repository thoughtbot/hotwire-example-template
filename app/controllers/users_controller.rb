class UsersController < ApplicationController
  def index
    @users = User.without Current.user
  end
end
