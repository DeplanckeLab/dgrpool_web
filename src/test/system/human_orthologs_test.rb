require "application_system_test_case"

class HumanOrthologsTest < ApplicationSystemTestCase
  setup do
    @human_ortholog = human_orthologs(:one)
  end

  test "visiting the index" do
    visit human_orthologs_url
    assert_selector "h1", text: "Human orthologs"
  end

  test "should create human ortholog" do
    visit human_orthologs_url
    click_on "New human ortholog"

    click_on "Create Human ortholog"

    assert_text "Human ortholog was successfully created"
    click_on "Back"
  end

  test "should update Human ortholog" do
    visit human_ortholog_url(@human_ortholog)
    click_on "Edit this human ortholog", match: :first

    click_on "Update Human ortholog"

    assert_text "Human ortholog was successfully updated"
    click_on "Back"
  end

  test "should destroy Human ortholog" do
    visit human_ortholog_url(@human_ortholog)
    click_on "Destroy this human ortholog", match: :first

    assert_text "Human ortholog was successfully destroyed"
  end
end
