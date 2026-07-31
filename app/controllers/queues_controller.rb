class QueuesController < ApplicationController
  # Jumps to a profile's current queue (creating one if needed).
  def current
    profile = Profile.find(params[:id])
    redirect_to queue_path(profile.current_queue)
  end

  def show
    @queue = ProfileQueue.includes(profile: :user).find(params[:id])
    @profile = @queue.profile
    @in_progress = @queue.in_progress_conversation
    # Active = pending + in_progress (unfinished, non-deleted). Pin the in-progress
    # conversation to the top, then pending conversations newest-first.
    @conversations =
      @queue.conversations
            .active
            .includes(:answers)
            .sort_by { |c| [ c.in_progress? ? 0 : 1, -c.created_at.to_f ] }
  end
end
