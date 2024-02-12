require "test_helper"

class SnpsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @snp = snps(:one)
  end

  test "should get index" do
    get snps_url
    assert_response :success
  end

  test "should get new" do
    get new_snp_url
    assert_response :success
  end

  test "should create snp" do
    assert_difference("Snp.count") do
      post snps_url, params: { snp: {  } }
    end

    assert_redirected_to snp_url(Snp.last)
  end

  test "should show snp" do
    get snp_url(@snp)
    assert_response :success
  end

  test "should get edit" do
    get edit_snp_url(@snp)
    assert_response :success
  end

  test "should update snp" do
    patch snp_url(@snp), params: { snp: {  } }
    assert_redirected_to snp_url(@snp)
  end

  test "should destroy snp" do
    assert_difference("Snp.count", -1) do
      delete snp_url(@snp)
    end

    assert_redirected_to snps_url
  end
end
