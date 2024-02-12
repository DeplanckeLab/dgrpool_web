require "test_helper"

class DgrpLinesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @dgrp_line = dgrp_lines(:one)
  end

  test "should get index" do
    get dgrp_lines_url
    assert_response :success
  end

  test "should get new" do
    get new_dgrp_line_url
    assert_response :success
  end

  test "should create dgrp_line" do
    assert_difference("DgrpLine.count") do
      post dgrp_lines_url, params: { dgrp_line: {  } }
    end

    assert_redirected_to dgrp_line_url(DgrpLine.last)
  end

  test "should show dgrp_line" do
    get dgrp_line_url(@dgrp_line)
    assert_response :success
  end

  test "should get edit" do
    get edit_dgrp_line_url(@dgrp_line)
    assert_response :success
  end

  test "should update dgrp_line" do
    patch dgrp_line_url(@dgrp_line), params: { dgrp_line: {  } }
    assert_redirected_to dgrp_line_url(@dgrp_line)
  end

  test "should destroy dgrp_line" do
    assert_difference("DgrpLine.count", -1) do
      delete dgrp_line_url(@dgrp_line)
    end

    assert_redirected_to dgrp_lines_url
  end
end
