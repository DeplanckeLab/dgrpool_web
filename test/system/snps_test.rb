require "application_system_test_case"

class SnpsTest < ApplicationSystemTestCase
  setup do
    @snp = snps(:one)
  end

  test "visiting the index" do
    visit snps_url
    assert_selector "h1", text: "Snps"
  end

  test "should create snp" do
    visit snps_url
    click_on "New snp"

    click_on "Create Snp"

    assert_text "Snp was successfully created"
    click_on "Back"
  end

  test "should update Snp" do
    visit snp_url(@snp)
    click_on "Edit this snp", match: :first

    click_on "Update Snp"

    assert_text "Snp was successfully updated"
    click_on "Back"
  end

  test "should destroy Snp" do
    visit snp_url(@snp)
    click_on "Destroy this snp", match: :first

    assert_text "Snp was successfully destroyed"
  end
end
