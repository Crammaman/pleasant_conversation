require "test_helper"

class QueuesControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_path, params: { username: "admin", password: "password123" }
    @queue = profile_queues(:alice_queue)
    @profile = profiles(:alice_profile)
  end

  test "current redirects to the profile's current queue" do
    get queue_profile_path(@profile)
    assert_redirected_to queue_path(@profile.current_queue)
  end

  test "current creates a queue when none is current" do
    profile = profiles(:bob_profile)
    profile.queues.update_all(current: false)

    get queue_profile_path(profile)
    assert_response :redirect
    assert profile.reload.current_queue.current?
  end

  test "show lists only active conversations" do
    finished = conversations(:catch_up)
    finished.update!(state: "finished")
    deleted = conversations(:weekly_chat)
    deleted.update!(state: "deleted")

    get queue_path(@queue)
    assert_response :success
    assert_no_match(/Catch-up/, response.body)
    assert_no_match(/Weekly chat/, response.body)
  end

  test "show renders active conversations and their answers" do
    get queue_path(@queue)
    assert_response :success
    assert_match(/Catch-up/, response.body)
    assert_match(/Weekly chat/, response.body)
    assert_match(/Doing well, thanks!/, response.body)
    assert_match(/How are you feeling today\?/, response.body)
  end

  test "show pins the in-progress conversation first" do
    conversations(:catch_up).update!(state: "in_progress")

    get queue_path(@queue)
    assert_response :success
    assert_operator response.body.index("Catch-up"), :<, response.body.index("Weekly chat")
  end

  test "show renders an empty state when no active conversations" do
    @queue.conversations.update_all(state: "deleted")

    get queue_path(@queue)
    assert_response :success
    assert_match(/No conversations in this queue yet/, response.body)
  end
end
