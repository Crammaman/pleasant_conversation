class HomeController < ApplicationController
  def index
    @profiles = Profile.includes(:user).order(:id)
    @conversation_counts = Conversation.joins(:queue).group("queues.profile_id").count
  end
end
