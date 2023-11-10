require "test_helper"

class SnpTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @snp_type = snp_types(:one)
  end

  test "should get index" do
    get snp_types_url
    assert_response :success
  end

  test "should get new" do
    get new_snp_type_url
    assert_response :success
  end

  test "should create snp_type" do
    assert_difference("SnpType.count") do
      post snp_types_url, params: { snp_type: {  } }
    end

    assert_redirected_to snp_type_url(SnpType.last)
  end

  test "should show snp_type" do
    get snp_type_url(@snp_type)
    assert_response :success
  end

  test "should get edit" do
    get edit_snp_type_url(@snp_type)
    assert_response :success
  end

  test "should update snp_type" do
    patch snp_type_url(@snp_type), params: { snp_type: {  } }
    assert_redirected_to snp_type_url(@snp_type)
  end

  test "should destroy snp_type" do
    assert_difference("SnpType.count", -1) do
      delete snp_type_url(@snp_type)
    end

    assert_redirected_to snp_types_url
  end
end
