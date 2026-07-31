require "test_helper"

class ConversationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_path, params: { username: "admin", password: "password123" }
    @queue = profile_queues(:alice_queue)
  end

  test "new builds one answer per profile question in order" do
    get new_queue_conversation_path(@queue)
    assert_response :success
    assert_match(/How are you feeling today\?/, response.body)
    assert_match(/Preferred topic/, response.body)
    assert_match(/Length of chat/, response.body)
  end

  test "create makes a conversation with nested answers" do
    assert_difference -> { @queue.conversations.count }, 1 do
      assert_difference -> { Answer.count }, 3 do
        post queue_conversations_path(@queue), params: {
          conversation: {
            name: "Evening chat",
            answers_attributes: {
              "0" => { question_id: questions(:feeling).id, value: "Great" },
              "1" => { question_id: questions(:topic).id, value: "Work" },
              "2" => { question_id: questions(:length).id, value: "Short" }
            }
          }
        }
      end
    end

    conversation = @queue.conversations.order(:created_at).last
    assert_redirected_to queue_path(@queue)
    assert_equal "Evening chat", conversation.name
    assert_equal "pending", conversation.state
    # question_text is snapshotted from the question.
    assert_equal "How are you feeling today?",
                 conversation.answers.find_by(question_id: questions(:feeling).id).question_text
  end

  test "create re-renders new on invalid input" do
    assert_no_difference -> { Conversation.count } do
      post queue_conversations_path(@queue), params: {
        conversation: { name: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "start sets a pending conversation to in_progress" do
    conversation = conversations(:catch_up)
    patch start_conversation_path(conversation)
    assert_redirected_to queue_path(@queue)
    assert_equal "in_progress", conversation.reload.state
  end

  test "start is rejected while another conversation is in progress" do
    conversations(:catch_up).update!(state: "in_progress")
    other = conversations(:weekly_chat)

    patch start_conversation_path(other)
    assert_redirected_to queue_path(@queue)
    assert_equal "pending", other.reload.state
    follow_redirect!
    assert_match(/already in progress/, response.body)
  end

  test "finish moves an in-progress conversation to finished" do
    conversation = conversations(:catch_up)
    conversation.update!(state: "in_progress")

    patch finish_conversation_path(conversation)
    assert_redirected_to queue_path(@queue)
    assert_equal "finished", conversation.reload.state
  end

  test "finish is rejected for a pending conversation" do
    conversation = conversations(:catch_up)
    patch finish_conversation_path(conversation)
    assert_equal "pending", conversation.reload.state
  end

  test "remove soft-deletes the conversation" do
    conversation = conversations(:catch_up)
    patch remove_conversation_path(conversation)
    assert_redirected_to queue_path(@queue)
    assert_equal "deleted", conversation.reload.state
  end
end
