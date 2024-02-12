require "application_system_test_case"

class GwasResultsTest < ApplicationSystemTestCase
  setup do
    @gwas_result = gwas_results(:one)
  end

  test "visiting the index" do
    visit gwas_results_url
    assert_selector "h1", text: "Gwas results"
  end

  test "should create gwas result" do
    visit gwas_results_url
    click_on "New gwas result"

    click_on "Create Gwas result"

    assert_text "Gwas result was successfully created"
    click_on "Back"
  end

  test "should update Gwas result" do
    visit gwas_result_url(@gwas_result)
    click_on "Edit this gwas result", match: :first

    click_on "Update Gwas result"

    assert_text "Gwas result was successfully updated"
    click_on "Back"
  end

  test "should destroy Gwas result" do
    visit gwas_result_url(@gwas_result)
    click_on "Destroy this gwas result", match: :first

    assert_text "Gwas result was successfully destroyed"
  end
end
