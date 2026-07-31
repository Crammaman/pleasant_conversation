class UsersController < ApplicationController
  def new
    @user = User.new
    @profiles = Profile.includes(:user, :questions).all
  end

  def create
    @user = User.new(user_params)
    converser = params[:converser] == "1"

    begin
      ActiveRecord::Base.transaction do
        @user.save!

        if converser
          profile = @user.create_profile!
          submitted_questions.each_with_index do |q, index|
            profile.questions.create!(
              text: q[:text],
              question_type: q[:question_type],
              config: config_for(q),
              position: index + 1
            )
          end
        end
      end

      redirect_to root_path, notice: "User created"
    rescue ActiveRecord::RecordInvalid => e
      @profiles = Profile.includes(:user, :questions).all
      flash.now[:alert] = e.record.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :name, :password, :password_confirmation)
  end

  # Returns the submitted questions as an array of hashes, ignoring blank rows.
  def submitted_questions
    Array(params[:questions]).filter_map do |q|
      q = q.respond_to?(:to_unsafe_h) ? q.to_unsafe_h : q
      text = q[:text].to_s.strip
      next if text.empty?

      {
        text: text,
        question_type: q[:question_type].to_s,
        options: parse_options(q[:options])
      }
    end
  end

  def config_for(question)
    if %w[select radio].include?(question[:question_type])
      { "options" => question[:options] }
    else
      {}
    end
  end

  # Options arrive as a textarea/input value: one per line or comma-separated.
  def parse_options(raw)
    raw.to_s.split(/[\n,]+/).map(&:strip).reject(&:empty?)
  end
end
