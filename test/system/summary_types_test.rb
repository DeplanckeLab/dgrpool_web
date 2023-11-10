require "application_system_test_case"

class SummaryTypesTest < ApplicationSystemTestCase
  setup do
    @summary_type = summary_types(:one)
  end

  test "visiting the index" do
    visit summary_types_url
    assert_selector "h1", text: "Summary types"
  end

  test "should create summary type" do
    visit summary_types_url
    click_on "New summary type"

    click_on "Create Summary type"

    assert_text "Summary type was successfully created"
    click_on "Back"
  end

  test "should update Summary type" do
    visit summary_type_url(@summary_type)
    click_on "Edit this summary type", match: :first

    click_on "Update Summary type"

    assert_text "Summary type was successfully updated"
    click_on "Back"
  end

  test "should destroy Summary type" do
    visit summary_type_url(@summary_type)
    click_on "Destroy this summary type", match: :first

    assert_text "Summary type was successfully destroyed"
  end
end
