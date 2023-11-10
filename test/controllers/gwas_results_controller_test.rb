require "test_helper"

class GwasResultsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @gwas_result = gwas_results(:one)
  end

  test "should get index" do
    get gwas_results_url
    assert_response :success
  end

  test "should get new" do
    get new_gwas_result_url
    assert_response :success
  end

  test "should create gwas_result" do
    assert_difference("GwasResult.count") do
      post gwas_results_url, params: { gwas_result: {  } }
    end

    assert_redirected_to gwas_result_url(GwasResult.last)
  end

  test "should show gwas_result" do
    get gwas_result_url(@gwas_result)
    assert_response :success
  end

  test "should get edit" do
    get edit_gwas_result_url(@gwas_result)
    assert_response :success
  end

  test "should update gwas_result" do
    patch gwas_result_url(@gwas_result), params: { gwas_result: {  } }
    assert_redirected_to gwas_result_url(@gwas_result)
  end

  test "should destroy gwas_result" do
    assert_difference("GwasResult.count", -1) do
      delete gwas_result_url(@gwas_result)
    end

    assert_redirected_to gwas_results_url
  end
end
