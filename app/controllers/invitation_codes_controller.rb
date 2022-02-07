class InvitationCodesController < ApplicationController
  def show
    @invitation_code = params[:id]
  end
end
