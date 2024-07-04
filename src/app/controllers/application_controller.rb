class ApplicationController < ActionController::Base
  helper_method :admin?,  :curator?, :accessible?, :plain_text_file?
  before_action :init_var, :init_session
       

  before_action :configure_permitted_parameters, if: :devise_controller?
  
  def admin_emails
    return ['fabrice.david@epfl.ch','vincent.gardeux@epfl.ch']
  end

  def curator_emails
    return ['romain.rochepeau@epfl.ch','gardeux.vincent@gmail.com', 'fab.dav@gmail.com', 'emily.rosschaert@student.kuleuven.be', 'roelbevers@gmail.com']
  end


  def admin?
    current_user and admin_emails.include?(current_user.email)
  end

  def is_admin? u
    u and admin_emails.include?(u.email)
  end
  
  def curator?
    current_user and (curator_emails.include?(current_user.email) or admin_emails.include?(current_user.email))
  end

  def is_curator? u
    u and curator_emails.include?(u.email)
  end
  
  def authorize_admin
  #  logger.debug "IP:" + ip_restricted_access(nil, request).to_json
    if !admin? #and ip_restricted_access(nil, request) != true
      redirect_to unauthorized_path
    end
  end
  
  def authorize_curator
    if !curator? #and ip_restricted_access(nil, request) != true
      redirect_to unauthorized_path
    end
  end
    
  def accessible? e
    admin? or (e and ((current_user and (e.user_id == current_user.id))))
  end

  def create_key m, n
    tmp_key = Array.new(n){[*'0'..'9', *'a'..'z'].sample}.join
    while m.where(:key => tmp_key).count > 0
      tmp_key = Array.new(n){[*'0'..'9', *'a'..'z'].sample}.join
    end
    return tmp_key
  end

  def init_var
    @h_legend = {:sex => {'F' => "Female", 'M' => "Male", 'NA' => "Unclassified sex"}}
    @h_sex_color = {'F' => '#F28C28', 'M' => '#0E4C92', 'NA' => '#CCCC77'}
    @chr = ["2L", "2R", "3R", "3L", "X", "4"]
    @list_sum_types = ['mean', 'median', 'variance', 'standard deviation', 'standard error', 'coefficient of variation']
  end

  def init_session
     session[:gs_settings]||={:limit => 10, :free_text => ''}
     session[:history]||=[]
#     session[:filter_gene_id]||=''
     session[:filter_gene_name]||=''
     session[:filter_by_pos]||=''
     session[:filter_binding_site]||=''
     session[:filter_involved_binding_site]||='0'
     session[:filter_variant_impact]||=''
  end

  def plain_text_file?(content)
    sample = content[0, 1024]
    non_text_bytes = sample.each_byte.count { |byte| byte < 9 || (byte > 13 && byte < 32) || byte > 126 }
    
    # Consider the file as plain text if less than 5% of the bytes are non-text
    non_text_bytes.to_f / sample.size < 0.05
  end
  
  protected
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:name, :email, :password)}
    
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:name, :email, :password, :current_password)}
  end
  
end
