namespace :routes do
  desc "Check all GET routes for a successful response"
  task check: :environment do
    require 'net/http'
    require 'uri'
    
    # Define the methods to exclude: POST, PATCH, PUT, DELETE
    excluded_methods = %w[POST PATCH PUT DELETE]
    
    # Define the paths to exclude
    excluded_paths = [
      '/users/sign_in', # example path to exclude
      '/assets',        # usually you don't need to check asset paths
    ]

    Rails.application.routes.routes.each do |route|
      # Extract the HTTP verb, path, controller, and action from the route
      verb = route.verb.to_s.delete('^a-zA-Z') # Get the verb as a clean string
      path = route.path.spec.to_s.gsub('(.:format)', '')
      controller = route.defaults[:controller]
      action = route.defaults[:action]
      
      # Skip excluded methods and paths
      next if excluded_methods.include?(verb)
      next if excluded_paths.any? { |excluded| path.start_with?(excluded) }
      next if path.include?(':')  # Skip routes with parameters

      # Construct the URL
      url = URI.parse("http://localhost:3000#{path}")

      # Make a GET request to each route
      response = Net::HTTP.get_response(url)

      if response.is_a?(Net::HTTPSuccess)
        puts "SUCCESS: #{verb} #{path} -> 200 OK"
      else
        puts "ERROR: #{verb} #{path} -> #{response.code} #{response.message}"
      end
    rescue StandardError => e
      puts "ERROR: #{verb} #{path} -> #{e.message}"
    end
    sleep 3
  end
end
