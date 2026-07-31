class ConversationsController < ApplicationController
  before_action :set_queue, only: %i[new create]
  before_action :set_conversation, only: %i[start finish remove]

  def new
    @conversation = @queue.conversations.new
    # One answer per profile question, in position order.
    @questions = @queue.profile.questions.to_a
    @questions.each do |question|
      @conversation.answers.new(question: question, question_text: question.text)
    end
  end

  def create
    @conversation = @queue.conversations.new(conversation_params)

    if @conversation.save
      redirect_to queue_path(@queue), notice: "Conversation added."
    else
      @questions = @queue.profile.questions.to_a
      flash.now[:alert] = @conversation.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def start
    if @conversation.startable?
      @conversation.in_progress!
      redirect_to queue_path(@conversation.queue), notice: "Conversation started."
    else
      redirect_to queue_path(@conversation.queue), alert: "Another conversation is already in progress."
    end
  end

  def finish
    if @conversation.in_progress?
      @conversation.finished!
      redirect_to queue_path(@conversation.queue), notice: "Conversation finished."
    else
      redirect_to queue_path(@conversation.queue), alert: "Only an in-progress conversation can be finished."
    end
  end

  def remove
    @conversation.deleted!
    redirect_to queue_path(@conversation.queue), notice: "Conversation removed."
  end

  private

  def set_queue
    @queue = ProfileQueue.includes(profile: :questions).find(params[:queue_id])
  end

  def set_conversation
    @conversation = Conversation.find(params[:id])
  end

  def conversation_params
    params.require(:conversation).permit(
      :name,
      answers_attributes: %i[question_id value question_text]
    )
  end
end
