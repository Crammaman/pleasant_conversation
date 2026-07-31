require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  def login_as(username = "admin")
    post login_path, params: { username: username, password: "password123" }
  end

  test "new requires login" do
    get new_user_path
    assert_redirected_to login_path
  end

  test "new renders when logged in" do
    login_as
    get new_user_path
    assert_response :success
    assert_select "h1", "Add User"
  end

  test "create user without converser creates no profile" do
    login_as
    assert_difference("User.count", 1) do
      assert_no_difference("Profile.count") do
        post users_path, params: {
          user: {
            username: "carol",
            name: "Carol Smith",
            password: "password123",
            password_confirmation: "password123"
          },
          converser: "0"
        }
      end
    end
    assert_redirected_to root_path
    assert_equal "User created", flash[:notice]
    assert_nil User.find_by(username: "carol").profile
  end

  test "create ignores questions when converser is off" do
    login_as
    assert_no_difference("Question.count") do
      post users_path, params: {
        user: {
          username: "dave",
          name: "Dave Jones",
          password: "password123",
          password_confirmation: "password123"
        },
        converser: "0",
        questions: [ { text: "Ignored", question_type: "text", options: "" } ]
      }
    end
  end

  test "create with converser and questions creates profile and questions" do
    login_as
    assert_difference([ "User.count", "Profile.count" ], 1) do
      assert_difference("Question.count", 2) do
        post users_path, params: {
          user: {
            username: "erin",
            name: "Erin Fox",
            password: "password123",
            password_confirmation: "password123"
          },
          converser: "1",
          questions: [
            { text: "How are you?", question_type: "text", options: "" },
            { text: "Pick one", question_type: "select", options: "A\nB\nC" }
          ]
        }
      end
    end

    assert_redirected_to root_path
    profile = User.find_by(username: "erin").profile
    assert_not_nil profile

    questions = profile.questions.order(:position).to_a
    assert_equal [ 1, 2 ], questions.map(&:position)

    text_q = questions.first
    assert_equal "How are you?", text_q.text
    assert_equal "text", text_q.question_type
    assert_equal({}, text_q.config)

    select_q = questions.second
    assert_equal "select", select_q.question_type
    assert_equal({ "options" => %w[A B C] }, select_q.config)
  end

  test "create skips blank question rows" do
    login_as
    assert_difference("Question.count", 1) do
      post users_path, params: {
        user: {
          username: "frank",
          name: "Frank Hill",
          password: "password123",
          password_confirmation: "password123"
        },
        converser: "1",
        questions: [
          { text: "  ", question_type: "text", options: "" },
          { text: "Real question", question_type: "text", options: "" }
        ]
      }
    end
    profile = User.find_by(username: "frank").profile
    assert_equal 1, profile.questions.count
    assert_equal 1, profile.questions.first.position
  end

  test "validation failure re-renders new" do
    login_as
    assert_no_difference([ "User.count", "Profile.count" ]) do
      post users_path, params: {
        user: {
          username: "",
          name: "No Username",
          password: "password123",
          password_confirmation: "password123"
        },
        converser: "1",
        questions: [ { text: "Q", question_type: "text", options: "" } ]
      }
    end
    assert_response :unprocessable_entity
    assert_select "h1", "Add User"
    assert_select "input[value=?]", "No Username"
  end
end
