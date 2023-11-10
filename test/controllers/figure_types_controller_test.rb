require "test_helper"

class FigureTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @figure_type = figure_types(:one)
  end

  test "should get index" do
    get figure_types_url
    assert_response :success
  end

  test "should get new" do
    get new_figure_type_url
    assert_response :success
  end

  test "should create figure_type" do
    assert_difference("FigureType.count") do
      post figure_types_url, params: { figure_type: {  } }
    end

    assert_redirected_to figure_type_url(FigureType.last)
  end

  test "should show figure_type" do
    get figure_type_url(@figure_type)
    assert_response :success
  end

  test "should get edit" do
    get edit_figure_type_url(@figure_type)
    assert_response :success
  end

  test "should update figure_type" do
    patch figure_type_url(@figure_type), params: { figure_type: {  } }
    assert_redirected_to figure_type_url(@figure_type)
  end

  test "should destroy figure_type" do
    assert_difference("FigureType.count", -1) do
      delete figure_type_url(@figure_type)
    end

    assert_redirected_to figure_types_url
  end
end
