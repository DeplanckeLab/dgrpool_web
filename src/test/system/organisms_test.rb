require "application_system_test_case"

class OrganismsTest < ApplicationSystemTestCase
  setup do
    @organism = organisms(:one)
  end

  test "visiting the index" do
    visit organisms_url
    assert_selector "h1", text: "Organisms"
  end

  test "should create organism" do
    visit organisms_url
    click_on "New organism"

    click_on "Create Organism"

    assert_text "Organism was successfully created"
    click_on "Back"
  end

  test "should update Organism" do
    visit organism_url(@organism)
    click_on "Edit this organism", match: :first

    click_on "Update Organism"

    assert_text "Organism was successfully updated"
    click_on "Back"
  end

  test "should destroy Organism" do
    visit organism_url(@organism)
    click_on "Destroy this organism", match: :first

    assert_text "Organism was successfully destroyed"
  end
end
