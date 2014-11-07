class BluetrainNetwork
	require 'rest_client'

	def initialize (env) 
		@env = env
		@logger = Logger.new("net.log")
		RestClient.log = @logger
		@ssl_config = {
			:ssl_client_cert => OpenSSL::X509::Certificate.new(File.read("cert/client.crt")),
			:ssl_client_key => OpenSSL::PKey::RSA.new(File.read("cert/client.key")),
			:ssl_ca_file => "cert/ca_certificate.crt",
			:verify_ssl => OpenSSL::SSL::VERIFY_PEER
		}
	end

	def authenticate (user, password)
		@logger.info "Authenticating: Silencing log"
		RestClient.log = nil

		client = rest_client_for('sign_in')
		response = client.post(:user => { :email => user, :password => password })
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
		client = rest_client_for('update_plt')
		client.put({:user_email => @user_email, :user_token => @user_token,"presentation_layer_template"=>{"default"=>false, "kind"=>kind, "notes"=>nil, "title"=>template_name, "website_id"=>@website, "widget_id"=>nil, "default_content"=>content}, "website_id"=>@website}){|response, request, result, &block| BluetrainNetwork.handle_response(response, request, result, &block)}
	end

	def delete (template_name)
		client = rest_client_for('update_plt')
		client.delete(:params => {:user_email => @user_email, :user_token => @user_token,'presentation_layer_template[title]' => template_name,'presentation_layer_template[website_id]' => @website,  'presentation_layer_template[kind]' => 'template'}){|response, request, result, &block| BluetrainNetwork.handle_response(response, request, result, &block)}
	end

	def create (template_name, content, kind)
		client = rest_client_for('create_plt')
		client.post({:user_email => @user_email, :user_token => @user_token,"presentation_layer_template"=>{"default"=>false, "kind"=>kind, "notes"=>nil, "title"=>template_name, "website_id"=>@website, "widget_id"=>nil, "default_content"=>content}, "website_id"=>@website}){|response, request, result, &block| BluetrainNetwork.handle_response(response, request, result, &block)}
	end

	def get_templates
		client = rest_client_for('get_plt')
		client.get({:params => {:user_email => @user_email, :user_token => @user_token,:website_id => @website, :kind=>'all'}}).to_str
	end

	def get_websites
		client = rest_client_for('get_websites')
		client.get(:params => {:user_email => @user_email, :user_token => @user_token}).to_str
	end

	def get_widgets
		client = rest_client_for('get_widgets')
		client.get(:params => {:user_email => @user_email, :user_token => @user_token, :website_id => @website}).to_str
	end

	def update_widget (name, content, device)
		client = rest_client_for('update_widget')
		client.put(:user_email => @user_email, :user_token => @user_token,"widget"=>{"website_id"=>@website, "name"=>name}, "device_template"=>{"content" => content, "device" => device}, "website_id"=>@website){|response, request, result, &block| BluetrainNetwork.handle_response(response, request, result, &block)}
	end

	def create_widget (name, content)
		client = rest_client_for('create_widget')
		client.post(:user_email => @user_email, :user_token => @user_token,"widget"=>{"website_id"=>@website,"widget_json"=>content, "name"=>name}, "website_id"=>@website){|response, request, result, &block| BluetrainNetwork.handle_response(response, request, result, &block)}
	end

	def delete_widget (name)
		client = rest_client_for('delete_widget')
		client.delete(:user_email => @user_email, :user_token => @user_token,"widget"=>{"website_id"=>@website, "name"=>name}, "website_id"=>@website){|response, request, result, &block| BluetrainNetwork.handle_response(response, request, result, &block)}
	end

	def configure_widget (name, settings)
		client = rest_client_for('configure_widget')
		client.put(:user_email => @user_email, :user_token => @user_token,"widget"=>{"website_id"=>@website, "name"=>name, "settings"=>settings}, "website_id"=>@website){|response, request, result, &block| BluetrainNetwork.handle_response(response, request, result, &block)}
	end

	def delete_widget_device_template (name, device)
		client = rest_client_for('delete_widget_device_template')
		client.delete(:params => {:user_email => @user_email, :user_token => @user_token, "name"=>name, "device"=>device, "website_id"=>@website}){|response, request, result, &block| BluetrainNetwork.handle_response(response, request, result, &block)}
	end

	def get_widget_device_templates (name)
		client = rest_client_for('get_widget_device_templates')
		client.get(:params => { :user_email => @user_email, :user_token => @user_token, :website_id => @website, :name => name }).to_str
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

	private

	def path_for(route)
		"#{Bluetrain::ENV[@env]['host']}#{Bluetrain::ENV['paths'][route]}"
	end

	def rest_client_for(route)
		RestClient::Resource.new(path_for(route), @ssl_config)
	end
end
