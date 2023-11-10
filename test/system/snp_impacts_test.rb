require "application_system_test_case"

class SnpImpactsTest < ApplicationSystemTestCase
  setup do
    @snp_impact = snp_impacts(:one)
  end

  test "visiting the index" do
    visit snp_impacts_url
    assert_selector "h1", text: "Snp impacts"
  end

  test "should create snp impact" do
    visit snp_impacts_url
    click_on "New snp impact"

    click_on "Create Snp impact"

    assert_text "Snp impact was successfully created"
    click_on "Back"
  end

  test "should update Snp impact" do
    visit snp_impact_url(@snp_impact)
    click_on "Edit this snp impact", match: :first

    click_on "Update Snp impact"

    assert_text "Snp impact was successfully updated"
    click_on "Back"
  end

  test "should destroy Snp impact" do
    visit snp_impact_url(@snp_impact)
    click_on "Destroy this snp impact", match: :first

    assert_text "Snp impact was successfully destroyed"
  end
end
