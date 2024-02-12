require "test_helper"

class VarTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @var_type = var_types(:one)
  end

  test "should get index" do
    get var_types_url
    assert_response :success
  end

  test "should get new" do
    get new_var_type_url
    assert_response :success
  end

  test "should create var_type" do
    assert_difference("VarType.count") do
      post var_types_url, params: { var_type: {  } }
    end

    assert_redirected_to var_type_url(VarType.last)
  end

  test "should show var_type" do
    get var_type_url(@var_type)
    assert_response :success
  end

  test "should get edit" do
    get edit_var_type_url(@var_type)
    assert_response :success
  end

  test "should update var_type" do
    patch var_type_url(@var_type), params: { var_type: {  } }
    assert_redirected_to var_type_url(@var_type)
  end

  test "should destroy var_type" do
    assert_difference("VarType.count", -1) do
      delete var_type_url(@var_type)
    end

    assert_redirected_to var_types_url
  end
end
