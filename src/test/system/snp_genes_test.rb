require "application_system_test_case"

class SnpGenesTest < ApplicationSystemTestCase
  setup do
    @snp_gene = snp_genes(:one)
  end

  test "visiting the index" do
    visit snp_genes_url
    assert_selector "h1", text: "Snp genes"
  end

  test "should create snp gene" do
    visit snp_genes_url
    click_on "New snp gene"

    click_on "Create Snp gene"

    assert_text "Snp gene was successfully created"
    click_on "Back"
  end

  test "should update Snp gene" do
    visit snp_gene_url(@snp_gene)
    click_on "Edit this snp gene", match: :first

    click_on "Update Snp gene"

    assert_text "Snp gene was successfully updated"
    click_on "Back"
  end

  test "should destroy Snp gene" do
    visit snp_gene_url(@snp_gene)
    click_on "Destroy this snp gene", match: :first

    assert_text "Snp gene was successfully destroyed"
  end
end
