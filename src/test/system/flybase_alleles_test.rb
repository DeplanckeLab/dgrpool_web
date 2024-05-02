require "application_system_test_case"

class FlybaseAllelesTest < ApplicationSystemTestCase
  setup do
    @flybase_allele = flybase_alleles(:one)
  end

  test "visiting the index" do
    visit flybase_alleles_url
    assert_selector "h1", text: "Flybase alleles"
  end

  test "should create flybase allele" do
    visit flybase_alleles_url
    click_on "New flybase allele"

    click_on "Create Flybase allele"

    assert_text "Flybase allele was successfully created"
    click_on "Back"
  end

  test "should update Flybase allele" do
    visit flybase_allele_url(@flybase_allele)
    click_on "Edit this flybase allele", match: :first

    click_on "Update Flybase allele"

    assert_text "Flybase allele was successfully updated"
    click_on "Back"
  end

  test "should destroy Flybase allele" do
    visit flybase_allele_url(@flybase_allele)
    click_on "Destroy this flybase allele", match: :first

    assert_text "Flybase allele was successfully destroyed"
  end
end
