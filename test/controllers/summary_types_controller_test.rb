require "test_helper"

class SummaryTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @summary_type = summary_types(:one)
  end

  test "should get index" do
    get summary_types_url
    assert_response :success
  end

  test "should get new" do
    get new_summary_type_url
    assert_response :success
  end

  test "should create summary_type" do
    assert_difference("SummaryType.count") do
      post summary_types_url, params: { summary_type: {  } }
    end

    assert_redirected_to summary_type_url(SummaryType.last)
  end

  test "should show summary_type" do
    get summary_type_url(@summary_type)
    assert_response :success
  end

  test "should get edit" do
    get edit_summary_type_url(@summary_type)
    assert_response :success
  end

  test "should update summary_type" do
    patch summary_type_url(@summary_type), params: { summary_type: {  } }
    assert_redirected_to summary_type_url(@summary_type)
  end

  test "should destroy summary_type" do
    assert_difference("SummaryType.count", -1) do
      delete summary_type_url(@summary_type)
    end

    assert_redirected_to summary_types_url
  end
end
