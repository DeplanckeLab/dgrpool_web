require "application_system_test_case"

class DgrpStatusesTest < ApplicationSystemTestCase
  setup do
    @dgrp_status = dgrp_statuses(:one)
  end

  test "visiting the index" do
    visit dgrp_statuses_url
    assert_selector "h1", text: "Dgrp statuses"
  end

  test "should create dgrp status" do
    visit dgrp_statuses_url
    click_on "New dgrp status"

    click_on "Create Dgrp status"

    assert_text "Dgrp status was successfully created"
    click_on "Back"
  end

  test "should update Dgrp status" do
    visit dgrp_status_url(@dgrp_status)
    click_on "Edit this dgrp status", match: :first

    click_on "Update Dgrp status"

    assert_text "Dgrp status was successfully updated"
    click_on "Back"
  end

  test "should destroy Dgrp status" do
    visit dgrp_status_url(@dgrp_status)
    click_on "Destroy this dgrp status", match: :first

    assert_text "Dgrp status was successfully destroyed"
  end
end
