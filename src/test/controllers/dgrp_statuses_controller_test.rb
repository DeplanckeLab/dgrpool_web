require "test_helper"

class DgrpStatusesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @dgrp_status = dgrp_statuses(:one)
  end

  test "should get index" do
    get dgrp_statuses_url
    assert_response :success
  end

  test "should get new" do
    get new_dgrp_status_url
    assert_response :success
  end

  test "should create dgrp_status" do
    assert_difference("DgrpStatus.count") do
      post dgrp_statuses_url, params: { dgrp_status: {  } }
    end

    assert_redirected_to dgrp_status_url(DgrpStatus.last)
  end

  test "should show dgrp_status" do
    get dgrp_status_url(@dgrp_status)
    assert_response :success
  end

  test "should get edit" do
    get edit_dgrp_status_url(@dgrp_status)
    assert_response :success
  end

  test "should update dgrp_status" do
    patch dgrp_status_url(@dgrp_status), params: { dgrp_status: {  } }
    assert_redirected_to dgrp_status_url(@dgrp_status)
  end

  test "should destroy dgrp_status" do
    assert_difference("DgrpStatus.count", -1) do
      delete dgrp_status_url(@dgrp_status)
    end

    assert_redirected_to dgrp_statuses_url
  end
end
