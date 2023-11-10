require "application_system_test_case"

class SnpTypesTest < ApplicationSystemTestCase
  setup do
    @snp_type = snp_types(:one)
  end

  test "visiting the index" do
    visit snp_types_url
    assert_selector "h1", text: "Snp types"
  end

  test "should create snp type" do
    visit snp_types_url
    click_on "New snp type"

    click_on "Create Snp type"

    assert_text "Snp type was successfully created"
    click_on "Back"
  end

  test "should update Snp type" do
    visit snp_type_url(@snp_type)
    click_on "Edit this snp type", match: :first

    click_on "Update Snp type"

    assert_text "Snp type was successfully updated"
    click_on "Back"
  end

  test "should destroy Snp type" do
    visit snp_type_url(@snp_type)
    click_on "Destroy this snp type", match: :first

    assert_text "Snp type was successfully destroyed"
  end
end
