require "application_system_test_case"

class GenesTest < ApplicationSystemTestCase
  setup do
    @gene = genes(:one)
  end

  test "visiting the index" do
    visit genes_url
    assert_selector "h1", text: "Genes"
  end

  test "should create gene" do
    visit genes_url
    click_on "New gene"

    click_on "Create Gene"

    assert_text "Gene was successfully created"
    click_on "Back"
  end

  test "should update Gene" do
    visit gene_url(@gene)
    click_on "Edit this gene", match: :first

    click_on "Update Gene"

    assert_text "Gene was successfully updated"
    click_on "Back"
  end

  test "should destroy Gene" do
    visit gene_url(@gene)
    click_on "Destroy this gene", match: :first

    assert_text "Gene was successfully destroyed"
  end
end
