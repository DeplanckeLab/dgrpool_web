require "test_helper"

class SnpGenesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @snp_gene = snp_genes(:one)
  end

  test "should get index" do
    get snp_genes_url
    assert_response :success
  end

  test "should get new" do
    get new_snp_gene_url
    assert_response :success
  end

  test "should create snp_gene" do
    assert_difference("SnpGene.count") do
      post snp_genes_url, params: { snp_gene: {  } }
    end

    assert_redirected_to snp_gene_url(SnpGene.last)
  end

  test "should show snp_gene" do
    get snp_gene_url(@snp_gene)
    assert_response :success
  end

  test "should get edit" do
    get edit_snp_gene_url(@snp_gene)
    assert_response :success
  end

  test "should update snp_gene" do
    patch snp_gene_url(@snp_gene), params: { snp_gene: {  } }
    assert_redirected_to snp_gene_url(@snp_gene)
  end

  test "should destroy snp_gene" do
    assert_difference("SnpGene.count", -1) do
      delete snp_gene_url(@snp_gene)
    end

    assert_redirected_to snp_genes_url
  end
end
