require "application_system_test_case"

class OmaOrthologsTest < ApplicationSystemTestCase
  setup do
    @oma_ortholog = oma_orthologs(:one)
  end

  test "visiting the index" do
    visit oma_orthologs_url
    assert_selector "h1", text: "Oma orthologs"
  end

  test "should create oma ortholog" do
    visit oma_orthologs_url
    click_on "New oma ortholog"

    click_on "Create Oma ortholog"

    assert_text "Oma ortholog was successfully created"
    click_on "Back"
  end

  test "should update Oma ortholog" do
    visit oma_ortholog_url(@oma_ortholog)
    click_on "Edit this oma ortholog", match: :first

    click_on "Update Oma ortholog"

    assert_text "Oma ortholog was successfully updated"
    click_on "Back"
  end

  test "should destroy Oma ortholog" do
    visit oma_ortholog_url(@oma_ortholog)
    click_on "Destroy this oma ortholog", match: :first

    assert_text "Oma ortholog was successfully destroyed"
  end
end
