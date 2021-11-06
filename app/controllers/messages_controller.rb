class MessagesController < ApplicationController
  def index
    @user = find_user
    @messages = Message.latest_first.involving [ Current.user, @user ]
  end

  def create
    @user = find_user
    @message = Current.user.sent_messages.new message_params.merge(recipient: @user)

    @message.save!

    redirect_to user_messages_path(@user)
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end

  def find_user(id = params[:user_id])
    User.find id
  end
end
