require "application_system_test_case"

class DgrpLineStudiesTest < ApplicationSystemTestCase
  setup do
    @dgrp_line_study = dgrp_line_studies(:one)
  end

  test "visiting the index" do
    visit dgrp_line_studies_url
    assert_selector "h1", text: "Dgrp line studies"
  end

  test "should create dgrp line study" do
    visit dgrp_line_studies_url
    click_on "New dgrp line study"

    click_on "Create Dgrp line study"

    assert_text "Dgrp line study was successfully created"
    click_on "Back"
  end

  test "should update Dgrp line study" do
    visit dgrp_line_study_url(@dgrp_line_study)
    click_on "Edit this dgrp line study", match: :first

    click_on "Update Dgrp line study"

    assert_text "Dgrp line study was successfully updated"
    click_on "Back"
  end

  test "should destroy Dgrp line study" do
    visit dgrp_line_study_url(@dgrp_line_study)
    click_on "Destroy this dgrp line study", match: :first

    assert_text "Dgrp line study was successfully destroyed"
  end
end
