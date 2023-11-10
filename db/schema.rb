# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_04_03_201955) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "categories", id: :serial, force: :cascade do |t|
    t.text "name"
    t.integer "num"
    t.text "description"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "nber_studies"
  end

  create_table "categories_studies", id: false, force: :cascade do |t|
    t.integer "category_id"
    t.integer "study_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "dgrp_line_studies", id: :serial, force: :cascade do |t|
    t.integer "dgrp_line_id"
    t.integer "study_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "obsolete", default: false
  end

  create_table "dgrp_line_studies_phenotype_keywords", id: false, force: :cascade do |t|
    t.integer "dgrp_line_study_id"
    t.integer "phenotype_keyword_id"
  end

  create_table "dgrp_line_studies_phenotypes", id: false, force: :cascade do |t|
    t.integer "dgrp_line_study_id"
    t.integer "phenotype_id"
    t.index ["dgrp_line_study_id"], name: "dgrp_line_studies_phenotypes_dgrp_line_study_id_idx"
    t.index ["phenotype_id"], name: "dgrp_line_studies_phenotypes_phenotype_id_idx"
  end

  create_table "dgrp_lines", id: :serial, force: :cascade do |t|
    t.text "name"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "nber_studies"
    t.integer "nber_phenotypes"
    t.integer "dgrp_status_id"
    t.text "fbsn"
    t.integer "bloomington_id"
  end

  create_table "dgrp_statuses", id: :serial, force: :cascade do |t|
    t.text "name"
    t.text "label"
    t.text "css_class"
    t.text "description"
    t.text "url_mask"
  end

  create_table "figure_types", id: :serial, force: :cascade do |t|
    t.text "name"
  end

  create_table "figures", id: :serial, force: :cascade do |t|
    t.integer "study_id"
    t.integer "figure_type_id"
    t.text "attrs_json"
    t.text "caption"
    t.integer "user_id"
    t.text "phenotype_ids"
  end

  create_table "gwas_results", id: :serial, force: :cascade do |t|
    t.integer "snp_id"
    t.integer "phenotype_id"
    t.float "p_val"
    t.float "fdr"
    t.text "sex"
    t.index ["phenotype_id", "sex"], name: "gwas_results_phenotype_id_sex"
  end

  create_table "journals", id: :serial, force: :cascade do |t|
    t.text "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "ontologies", id: :serial, force: :cascade do |t|
    t.text "name"
    t.text "tag"
    t.text "file_url"
    t.text "format"
    t.text "latest_version"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "ontology_terms", id: :serial, force: :cascade do |t|
    t.integer "ontology_id"
    t.text "identifier"
    t.text "alt_identifiers"
    t.text "name"
    t.text "description"
    t.text "content_json"
    t.boolean "obsolete", default: false
    t.text "latest_version"
    t.text "related_gene_ids"
    t.text "related_pmids"
    t.text "node_gene_ids"
    t.text "node_term_ids"
    t.text "parent_term_ids"
    t.text "children_term_ids"
    t.text "lineage"
    t.boolean "original"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "ontology_terms_phenotypes", id: false, force: :cascade do |t|
    t.integer "ontology_term_id"
    t.integer "phenotype_id"
  end

  create_table "phenotype_keywords", id: :serial, force: :cascade do |t|
    t.text "name"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "phenotypes", id: :serial, force: :cascade do |t|
    t.text "name"
    t.text "description"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "study_id"
    t.boolean "obsolete", default: false
    t.integer "nber_dgrp_lines"
    t.integer "nber_sex_male"
    t.integer "nber_sex_female"
    t.integer "nber_sex_na"
    t.boolean "is_summary"
    t.boolean "is_numeric"
    t.boolean "is_continuous"
    t.integer "dataset_id"
    t.integer "summary_type_id"
    t.integer "unit_id"
    t.text "sex_by_dgrp"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "snps", id: :serial, force: :cascade do |t|
    t.text "chr"
    t.integer "pos"
    t.text "identifier"
    t.text "ref"
    t.text "alt"
    t.text "geno_string"
    t.text "gene_annots_json"
    t.text "regulatory_annots_json"
    t.text "annots_json"
    t.index ["identifier"], name: "identifier_snps"
  end

  create_table "statuses", id: :serial, force: :cascade do |t|
    t.text "name"
    t.text "css_class"
    t.text "label"
  end

  create_table "studies", id: :serial, force: :cascade do |t|
    t.text "title"
    t.text "authors_json"
    t.text "abstract"
    t.integer "journal_id"
    t.integer "pmid"
    t.text "doi"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "status_id"
    t.integer "submitter_id"
    t.integer "validator_id"
    t.text "first_author"
    t.text "volume"
    t.text "issue"
    t.integer "year"
    t.datetime "published_at", precision: nil
    t.text "authors"
    t.text "pheno_json_old"
    t.text "pheno_mean_json"
    t.text "pheno_median_json"
    t.text "comment"
    t.text "flybase_ref"
    t.text "description"
    t.text "repository_identifiers"
    t.text "pheno_json"
    t.text "pheno_sum_json"
    t.index ["doi"], name: "studies_doi_idx"
    t.index ["pmid"], name: "studies_pmid_idx"
  end

  create_table "summary_types", id: :serial, force: :cascade do |t|
    t.text "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "units", id: :serial, force: :cascade do |t|
    t.text "label"
    t.text "label_html"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "uploads", id: :serial, force: :cascade do |t|
    t.integer "study_id"
    t.text "filename"
    t.integer "version_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "var_types", id: :serial, force: :cascade do |t|
    t.text "name"
    t.text "description"
    t.text "impact"
    t.text "impact_class"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  add_foreign_key "categories", "users", name: "categories_user_id_fkey"
  add_foreign_key "categories_studies", "categories", name: "categories_studies_category_id_fkey"
  add_foreign_key "categories_studies", "studies", name: "categories_studies_study_id_fkey"
  add_foreign_key "dgrp_line_studies", "dgrp_lines", name: "dgrp_line_studies_dgrp_line_id_fkey"
  add_foreign_key "dgrp_line_studies", "studies", name: "dgrp_line_studies_study_id_fkey"
  add_foreign_key "dgrp_line_studies", "users", name: "dgrp_line_studies_user_id_fkey"
  add_foreign_key "dgrp_line_studies_phenotype_keywords", "dgrp_line_studies", name: "dgrp_line_studies_phenotype_keywords_dgrp_line_study_id_fkey"
  add_foreign_key "dgrp_line_studies_phenotype_keywords", "phenotype_keywords", name: "dgrp_line_studies_phenotype_keywords_phenotype_keyword_id_fkey"
  add_foreign_key "dgrp_line_studies_phenotypes", "dgrp_line_studies", name: "dgrp_line_studies_phenotypes_dgrp_line_study_id_fkey"
  add_foreign_key "dgrp_line_studies_phenotypes", "phenotypes", name: "dgrp_line_studies_phenotypes_phenotype_id_fkey"
  add_foreign_key "dgrp_lines", "dgrp_statuses", name: "dgrp_lines_dgrp_status_id_fkey"
  add_foreign_key "dgrp_lines", "users", name: "dgrp_lines_user_id_fkey"
  add_foreign_key "figures", "figure_types", name: "figures_figure_type_id_fkey"
  add_foreign_key "figures", "studies", name: "figures_study_id_fkey"
  add_foreign_key "figures", "users", name: "figures_user_id_fkey"
  add_foreign_key "gwas_results", "phenotypes", name: "gwas_results_phenotype_id_fkey"
  add_foreign_key "gwas_results", "snps", name: "gwas_results_snp_id_fkey"
  add_foreign_key "ontology_terms", "ontologies", name: "ontology_terms_ontology_id_fkey"
  add_foreign_key "ontology_terms_phenotypes", "ontology_terms", name: "ontology_terms_phenotypes_ontology_term_id_fkey"
  add_foreign_key "ontology_terms_phenotypes", "phenotypes", name: "ontology_terms_phenotypes_phenotype_id_fkey"
  add_foreign_key "phenotype_keywords", "users", name: "phenotype_keywords_user_id_fkey"
  add_foreign_key "phenotypes", "studies", name: "phenotypes_study_id_fkey"
  add_foreign_key "phenotypes", "summary_types", name: "phenotypes_summary_type_id_fkey"
  add_foreign_key "phenotypes", "units", name: "phenotypes_unit_id_fkey"
  add_foreign_key "phenotypes", "users", name: "phenotypes_user_id_fkey"
  add_foreign_key "studies", "journals", name: "studies_journal_id_fkey"
  add_foreign_key "studies", "statuses", name: "studies_status_id_fkey"
  add_foreign_key "studies", "users", column: "submitter_id", name: "studies_submitter_id_fkey"
  add_foreign_key "studies", "users", column: "validator_id", name: "studies_validator_id_fkey"
  add_foreign_key "uploads", "studies", name: "uploads_study_id_fkey"
end
