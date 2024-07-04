require "test_helper"

class HumanOrthologsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @human_ortholog = human_orthologs(:one)
  end

  test "should get index" do
    get human_orthologs_url
    assert_response :success
  end

  test "should get new" do
    get new_human_ortholog_url
    assert_response :success
  end

  test "should create human_ortholog" do
    assert_difference("HumanOrtholog.count") do
      post human_orthologs_url, params: { human_ortholog: {  } }
    end

    assert_redirected_to human_ortholog_url(HumanOrtholog.last)
  end

  test "should show human_ortholog" do
    get human_ortholog_url(@human_ortholog)
    assert_response :success
  end

  test "should get edit" do
    get edit_human_ortholog_url(@human_ortholog)
    assert_response :success
  end

  test "should update human_ortholog" do
    patch human_ortholog_url(@human_ortholog), params: { human_ortholog: {  } }
    assert_redirected_to human_ortholog_url(@human_ortholog)
  end

  test "should destroy human_ortholog" do
    assert_difference("HumanOrtholog.count", -1) do
      delete human_ortholog_url(@human_ortholog)
    end

    assert_redirected_to human_orthologs_url
  end
end
