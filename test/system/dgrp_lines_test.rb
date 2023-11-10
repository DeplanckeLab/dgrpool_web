require "application_system_test_case"

class DgrpLinesTest < ApplicationSystemTestCase
  setup do
    @dgrp_line = dgrp_lines(:one)
  end

  test "visiting the index" do
    visit dgrp_lines_url
    assert_selector "h1", text: "Dgrp lines"
  end

  test "should create dgrp line" do
    visit dgrp_lines_url
    click_on "New dgrp line"

    click_on "Create Dgrp line"

    assert_text "Dgrp line was successfully created"
    click_on "Back"
  end

  test "should update Dgrp line" do
    visit dgrp_line_url(@dgrp_line)
    click_on "Edit this dgrp line", match: :first

    click_on "Update Dgrp line"

    assert_text "Dgrp line was successfully updated"
    click_on "Back"
  end

  test "should destroy Dgrp line" do
    visit dgrp_line_url(@dgrp_line)
    click_on "Destroy this dgrp line", match: :first

    assert_text "Dgrp line was successfully destroyed"
  end
end
