class Question < ApplicationRecord
  QUESTION_TYPES = %w[text select radio].freeze

  belongs_to :profile

  has_many :answers, dependent: :nullify

  validates :text, presence: true
  validates :question_type, inclusion: { in: QUESTION_TYPES }

  scope :ordered, -> { order(:position) }

  # Options for select/radio questions live in the config json, e.g. {"options" => ["a", "b"]}
  def options
    Array(config&.dig("options"))
  end

  def duplicate_for(new_profile)
    new_profile.questions.new(text:, question_type:, config:, position:)
  end
end
