require "application_system_test_case"

class PhenotypesTest < ApplicationSystemTestCase
  setup do
    @phenotype = phenotypes(:one)
  end

  test "visiting the index" do
    visit phenotypes_url
    assert_selector "h1", text: "Phenotypes"
  end

  test "should create phenotype" do
    visit phenotypes_url
    click_on "New phenotype"

    click_on "Create Phenotype"

    assert_text "Phenotype was successfully created"
    click_on "Back"
  end

  test "should update Phenotype" do
    visit phenotype_url(@phenotype)
    click_on "Edit this phenotype", match: :first

    click_on "Update Phenotype"

    assert_text "Phenotype was successfully updated"
    click_on "Back"
  end

  test "should destroy Phenotype" do
    visit phenotype_url(@phenotype)
    click_on "Destroy this phenotype", match: :first

    assert_text "Phenotype was successfully destroyed"
  end
end
