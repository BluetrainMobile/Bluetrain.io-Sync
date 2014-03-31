class BluetrainNetwork
	require 'rest_client'

	def initialize (env) 
		@env = env
		@logger = Logger.new("net.log")
		RestClient.log = @logger
	end

	def authenticate (user, password)
		@logger.info "Authenticating: Silencing log"
		RestClient.log = nil

		response = RestClient.post "#{Bluetrain::ENV[@env]['host']}#{Bluetrain::ENV['paths']['sign_in']}", {:user=>{:email => user, :password => password}}
		response = JSON.load response
		result = false

		unless response['success'].nil?
			@user_email = user
			@user_token = response['token']
			result = true
		end

		@logger.info "Authentication Attempt Succeeded: #{result}"
		RestClient.log = @logger

		return result
	end

	def set_stored_credentials (user, token)
		@user_email = user
		@user_token = token
	end

	def set_website (website)
		@website = website
	end

	def get_auth_settings 
		{'email' => @user_email, 'token' => @user_token, 'website' => @website}
	end

	def update (template_name, head_content, body_content)
		RestClient.put("#{Bluetrain::ENV[@env]['host']}#{Bluetrain::ENV['paths']['update_plt']}", 
			{:user_email => @user_email, :user_token => @user_token,"presentation_layer_template"=>{"default"=>false, "kind"=>"template", "notes"=>nil, "title"=>template_name, "website_id"=>@website, "widget_id"=>nil, "default_head_content"=>head_content, "default_body_content"=>body_content}, "website_id"=>@website}){|response, request, result, &block| BluetrainNetwork.handle_response(response, request, result, &block)}
	end

	def delete (template_name)
		RestClient.delete("#{Bluetrain::ENV[@env]['host']}#{Bluetrain::ENV['paths']['update_plt']}",
			{:params => {:user_email => @user_email, :user_token => @user_token,"title"=>template_name,"website_id"=>@website}}){|response, request, result, &block| BluetrainNetwork.handle_response(response, request, result, &block)}
	end

	def create (template_name, head_content, body_content)
		RestClient.post("#{Bluetrain::ENV[@env]['host']}#{Bluetrain::ENV['paths']['create_plt']}", 
			{:user_email => @user_email, :user_token => @user_token,"presentation_layer_template"=>{"default"=>false, "kind"=>"template", "notes"=>nil, "title"=>template_name, "website_id"=>@website, "widget_id"=>nil, "default_head_content"=> head_content, "default_body_content"=> body_content}, "website_id"=>@website}){|response, request, result, &block| BluetrainNetwork.handle_response(response, request, result, &block)}
	end

	def get_templates
		(RestClient.get "#{Bluetrain::ENV[@env]['host']}#{Bluetrain::ENV['paths']['get_plt']}",
			{:params => {:user_email => @user_email, :user_token => @user_token,:website_id => @website}}).to_str
	end

	def get_websites
		(RestClient.get "#{Bluetrain::ENV[@env]['host']}#{Bluetrain::ENV['paths']['get_websites']}",
			{:params => {:user_email => @user_email, :user_token => @user_token}}).to_str
	end

	def self.handle_response (response, request, result, &block)
		case response.code
		when 302
			response
		when 500
			puts "Something went wrong! Your changes weren't saved."
		else 
			response.return!(request, result, &block) 
		end
	end
end