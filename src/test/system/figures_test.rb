require "application_system_test_case"

class FiguresTest < ApplicationSystemTestCase
  setup do
    @figure = figures(:one)
  end

  test "visiting the index" do
    visit figures_url
    assert_selector "h1", text: "Figures"
  end

  test "should create figure" do
    visit figures_url
    click_on "New figure"

    click_on "Create Figure"

    assert_text "Figure was successfully created"
    click_on "Back"
  end

  test "should update Figure" do
    visit figure_url(@figure)
    click_on "Edit this figure", match: :first

    click_on "Update Figure"

    assert_text "Figure was successfully updated"
    click_on "Back"
  end

  test "should destroy Figure" do
    visit figure_url(@figure)
    click_on "Destroy this figure", match: :first

    assert_text "Figure was successfully destroyed"
  end
end
