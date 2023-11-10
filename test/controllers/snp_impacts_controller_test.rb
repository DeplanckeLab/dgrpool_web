require "test_helper"

class SnpImpactsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @snp_impact = snp_impacts(:one)
  end

  test "should get index" do
    get snp_impacts_url
    assert_response :success
  end

  test "should get new" do
    get new_snp_impact_url
    assert_response :success
  end

  test "should create snp_impact" do
    assert_difference("SnpImpact.count") do
      post snp_impacts_url, params: { snp_impact: {  } }
    end

    assert_redirected_to snp_impact_url(SnpImpact.last)
  end

  test "should show snp_impact" do
    get snp_impact_url(@snp_impact)
    assert_response :success
  end

  test "should get edit" do
    get edit_snp_impact_url(@snp_impact)
    assert_response :success
  end

  test "should update snp_impact" do
    patch snp_impact_url(@snp_impact), params: { snp_impact: {  } }
    assert_redirected_to snp_impact_url(@snp_impact)
  end

  test "should destroy snp_impact" do
    assert_difference("SnpImpact.count", -1) do
      delete snp_impact_url(@snp_impact)
    end

    assert_redirected_to snp_impacts_url
  end
end
