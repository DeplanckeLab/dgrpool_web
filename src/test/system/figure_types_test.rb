require "application_system_test_case"

class FigureTypesTest < ApplicationSystemTestCase
  setup do
    @figure_type = figure_types(:one)
  end

  test "visiting the index" do
    visit figure_types_url
    assert_selector "h1", text: "Figure types"
  end

  test "should create figure type" do
    visit figure_types_url
    click_on "New figure type"

    click_on "Create Figure type"

    assert_text "Figure type was successfully created"
    click_on "Back"
  end

  test "should update Figure type" do
    visit figure_type_url(@figure_type)
    click_on "Edit this figure type", match: :first

    click_on "Update Figure type"

    assert_text "Figure type was successfully updated"
    click_on "Back"
  end

  test "should destroy Figure type" do
    visit figure_type_url(@figure_type)
    click_on "Destroy this figure type", match: :first

    assert_text "Figure type was successfully destroyed"
  end
end
