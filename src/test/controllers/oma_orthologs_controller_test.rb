require "test_helper"

class OmaOrthologsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @oma_ortholog = oma_orthologs(:one)
  end

  test "should get index" do
    get oma_orthologs_url
    assert_response :success
  end

  test "should get new" do
    get new_oma_ortholog_url
    assert_response :success
  end

  test "should create oma_ortholog" do
    assert_difference("OmaOrtholog.count") do
      post oma_orthologs_url, params: { oma_ortholog: {  } }
    end

    assert_redirected_to oma_ortholog_url(OmaOrtholog.last)
  end

  test "should show oma_ortholog" do
    get oma_ortholog_url(@oma_ortholog)
    assert_response :success
  end

  test "should get edit" do
    get edit_oma_ortholog_url(@oma_ortholog)
    assert_response :success
  end

  test "should update oma_ortholog" do
    patch oma_ortholog_url(@oma_ortholog), params: { oma_ortholog: {  } }
    assert_redirected_to oma_ortholog_url(@oma_ortholog)
  end

  test "should destroy oma_ortholog" do
    assert_difference("OmaOrtholog.count", -1) do
      delete oma_ortholog_url(@oma_ortholog)
    end

    assert_redirected_to oma_orthologs_url
  end
end
