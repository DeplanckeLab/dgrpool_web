Rails.application.routes.draw do
  resources :oma_orthologs
  resources :human_orthologs
  resources :organisms
  resources :flybase_alleles
  resources :genes do
    collection do
      get :autocomplete
      get :search
      post :do_search
      post :set_search_session
    end
  end

  resources :snp_genes
  resources :snp_impacts
  resources :snp_types
  resources :var_types
  resources :gwas_results do
    collection do
      get :search
      get :get_search
      post :do_search
      post :set_search_session
    end
  end
  resources :snps do
    get :get_phewas
  end
  resources :units
  resources :uploads
  resources :summary_types
  resources :figures
  resources :figure_types
  resources :dgrp_statuses
  resources :dgrp_line_studies
  resources :dgrp_lines
  resources :journals
  resources :statuses
  resources :studies do
    member do
      get :get_file
      get :upload_form
      post :parse_dataset
    #  post :integrate_dataset
      post :upd_cats
      post :upd_disabled_phenotypes
      post :upd_disabled_dgrp_line_studies
      post :del_dataset
    end
  end
  resources :home do
    collection do
      get :upd_export
      post :parse_dataset
      get :check_pheno
      post :compute_my_pheno_correlation
      get :pheno_correlation
      post :compute_correlation
      get :gwas_analysis
      get :get_gwas_results
    end
  end
  devise_for :users
  devise_scope :user do
    get '/users/sign_out' => 'devise/sessions#destroy'
  end
  resources :phenotypes do
    member do
      get :compute_correlation
      get :gwas_analysis
      get :get_phewas
    end
    collection do
      get :autocomplete
      get :get_gwas_boxplot
    end
  end
  resources :categories
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  match '/unauthorized' => 'home#unauthorized', :via => [:get]
  match '/check_pheno' => 'home#check_pheno', :via => [:get]
  match '/parse_dataset' => 'home#parse_dataset', :via => [:post]
  match '/compute_my_pheno_correlation' => 'home#compute_my_pheno_correlation', :via => [:post]
  match '/pheno_correlation' => 'home#pheno_correlation', :via => [:get]
  match '/compute_correlation' => 'home#compute_correlation', :via => [:post]
  match '/gwas_analysis' => 'home#gwas_analysis', :via => [:get]

  root "home#welcome"


end
