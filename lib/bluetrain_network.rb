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

	def update (template_name, content, kind)
		RestClient.put("#{Bluetrain::ENV[@env]['host']}#{Bluetrain::ENV['paths']['update_plt']}", 
			{:user_email => @user_email, :user_token => @user_token,"presentation_layer_template"=>{"default"=>false, "kind"=>kind, "notes"=>nil, "title"=>template_name, "website_id"=>@website, "widget_id"=>nil, "default_content"=>content}, "website_id"=>@website}){|response, request, result, &block| BluetrainNetwork.handle_response(response, request, result, &block)}
	end

	def delete (template_name)
		RestClient.delete("#{Bluetrain::ENV[@env]['host']}#{Bluetrain::ENV['paths']['update_plt']}",
			{:params => {:user_email => @user_email, :user_token => @user_token,"title"=>template_name,"website_id"=>@website}}){|response, request, result, &block| BluetrainNetwork.handle_response(response, request, result, &block)}
	end

	def create (template_name, content, kind)
		RestClient.post("#{Bluetrain::ENV[@env]['host']}#{Bluetrain::ENV['paths']['create_plt']}", 
			{:user_email => @user_email, :user_token => @user_token,"presentation_layer_template"=>{"default"=>false, "kind"=>kind, "notes"=>nil, "title"=>template_name, "website_id"=>@website, "widget_id"=>nil, "default_content"=>content}, "website_id"=>@website}){|response, request, result, &block| BluetrainNetwork.handle_response(response, request, result, &block)}
	end

	def get_templates
		(RestClient.get "#{Bluetrain::ENV[@env]['host']}#{Bluetrain::ENV['paths']['get_plt']}",
			{:params => {:user_email => @user_email, :user_token => @user_token,:website_id => @website, :kind=>'all'}}).to_str
	end

	def get_websites
		(RestClient.get "#{Bluetrain::ENV[@env]['host']}#{Bluetrain::ENV['paths']['get_websites']}",
			{:params => {:user_email => @user_email, :user_token => @user_token}}).to_str
	end

	def get_widgets
		(RestClient.get "#{Bluetrain::ENV[@env]['host']}#{Bluetrain::ENV['paths']['get_widgets']}",
			{:params => {:user_email => @user_email, :user_token => @user_token, :website_id => @website}}).to_str
	end

	def update_widget (name, content, device)
		RestClient.put("#{Bluetrain::ENV[@env]['host']}#{Bluetrain::ENV['paths']['update_widget']}", 
			{:user_email => @user_email, :user_token => @user_token,"widget"=>{"website_id"=>@website, "name"=>name}, "device_template"=>{"content" => content, "device" => device}, "website_id"=>@website}){|response, request, result, &block| BluetrainNetwork.handle_response(response, request, result, &block)}
	end

	def create_widget (name, content)
		RestClient.post("#{Bluetrain::ENV[@env]['host']}#{Bluetrain::ENV['paths']['create_widget']}", 
			{:user_email => @user_email, :user_token => @user_token,"widget"=>{"website_id"=>@website,"widget_json"=>content, "name"=>name}, "website_id"=>@website}){|response, request, result, &block| BluetrainNetwork.handle_response(response, request, result, &block)}
	end

	def delete_widget (name)
		RestClient.delete("#{Bluetrain::ENV[@env]['host']}#{Bluetrain::ENV['paths']['delete_widget']}", 
			{:user_email => @user_email, :user_token => @user_token,"widget"=>{"website_id"=>@website, "name"=>name}, "website_id"=>@website}){|response, request, result, &block| BluetrainNetwork.handle_response(response, request, result, &block)}
	end

	def configure_widget (name, settings)
		RestClient.put("#{Bluetrain::ENV[@env]['host']}#{Bluetrain::ENV['paths']['configure_widget']}", 
			{:user_email => @user_email, :user_token => @user_token,"widget"=>{"website_id"=>@website, "name"=>name, "settings"=>settings}, "website_id"=>@website}){|response, request, result, &block| BluetrainNetwork.handle_response(response, request, result, &block)}
	end

	def delete_widget_device_template (name, device)
		RestClient.delete("#{Bluetrain::ENV[@env]['host']}#{Bluetrain::ENV['paths']['delete_widget_device_template']}", 
			{:params => {:user_email => @user_email, :user_token => @user_token, "name"=>name, "device"=>device, "website_id"=>@website}}){|response, request, result, &block| BluetrainNetwork.handle_response(response, request, result, &block)}
	end

	def get_widget_device_templates (name)
		(RestClient.get "#{Bluetrain::ENV[@env]['host']}#{Bluetrain::ENV['paths']['get_widget_device_templates']}",
			{:params => {:user_email => @user_email, :user_token => @user_token, :website_id => @website, :name => name}}).to_str
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