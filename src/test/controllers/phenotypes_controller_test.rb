require "test_helper"

class PhenotypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @phenotype = phenotypes(:one)
  end

  test "should get index" do
    get phenotypes_url
    assert_response :success
  end

  test "should get new" do
    get new_phenotype_url
    assert_response :success
  end

  test "should create phenotype" do
    assert_difference("Phenotype.count") do
      post phenotypes_url, params: { phenotype: {  } }
    end

    assert_redirected_to phenotype_url(Phenotype.last)
  end

  test "should show phenotype" do
    get phenotype_url(@phenotype)
    assert_response :success
  end

  test "should get edit" do
    get edit_phenotype_url(@phenotype)
    assert_response :success
  end

  test "should update phenotype" do
    patch phenotype_url(@phenotype), params: { phenotype: {  } }
    assert_redirected_to phenotype_url(@phenotype)
  end

  test "should destroy phenotype" do
    assert_difference("Phenotype.count", -1) do
      delete phenotype_url(@phenotype)
    end

    assert_redirected_to phenotypes_url
  end
end
