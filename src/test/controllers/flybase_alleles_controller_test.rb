require "test_helper"

class FlybaseAllelesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @flybase_allele = flybase_alleles(:one)
  end

  test "should get index" do
    get flybase_alleles_url
    assert_response :success
  end

  test "should get new" do
    get new_flybase_allele_url
    assert_response :success
  end

  test "should create flybase_allele" do
    assert_difference("FlybaseAllele.count") do
      post flybase_alleles_url, params: { flybase_allele: {  } }
    end

    assert_redirected_to flybase_allele_url(FlybaseAllele.last)
  end

  test "should show flybase_allele" do
    get flybase_allele_url(@flybase_allele)
    assert_response :success
  end

  test "should get edit" do
    get edit_flybase_allele_url(@flybase_allele)
    assert_response :success
  end

  test "should update flybase_allele" do
    patch flybase_allele_url(@flybase_allele), params: { flybase_allele: {  } }
    assert_redirected_to flybase_allele_url(@flybase_allele)
  end

  test "should destroy flybase_allele" do
    assert_difference("FlybaseAllele.count", -1) do
      delete flybase_allele_url(@flybase_allele)
    end

    assert_redirected_to flybase_alleles_url
  end
end
