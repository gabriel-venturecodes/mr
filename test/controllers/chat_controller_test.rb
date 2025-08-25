require "test_helper"

class ChatControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get chat_index_url
    assert_response :success
  end

  test "should get analyze" do
    get chat_analyze_url
    assert_response :success
  end

  test "should get analysis_status" do
    get chat_analysis_status_url
    assert_response :success
  end
end
