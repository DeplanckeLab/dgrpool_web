require "test_helper"

class DgrpLineStudiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @dgrp_line_study = dgrp_line_studies(:one)
  end

  test "should get index" do
    get dgrp_line_studies_url
    assert_response :success
  end

  test "should get new" do
    get new_dgrp_line_study_url
    assert_response :success
  end

  test "should create dgrp_line_study" do
    assert_difference("DgrpLineStudy.count") do
      post dgrp_line_studies_url, params: { dgrp_line_study: {  } }
    end

    assert_redirected_to dgrp_line_study_url(DgrpLineStudy.last)
  end

  test "should show dgrp_line_study" do
    get dgrp_line_study_url(@dgrp_line_study)
    assert_response :success
  end

  test "should get edit" do
    get edit_dgrp_line_study_url(@dgrp_line_study)
    assert_response :success
  end

  test "should update dgrp_line_study" do
    patch dgrp_line_study_url(@dgrp_line_study), params: { dgrp_line_study: {  } }
    assert_redirected_to dgrp_line_study_url(@dgrp_line_study)
  end

  test "should destroy dgrp_line_study" do
    assert_difference("DgrpLineStudy.count", -1) do
      delete dgrp_line_study_url(@dgrp_line_study)
    end

    assert_redirected_to dgrp_line_studies_url
  end
end
