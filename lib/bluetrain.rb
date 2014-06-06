class Bluetrain < Thor

	# External Requirements
	require 'rubygems' 
	require 'bundler/setup' 
	require 'listen'
	require 'io/console'
	require 'json'
	require 'fileutils'

	# Internal Requirements
	require 'bluetrain_network'
	require 'bluetrain_file_helper'

	# Configuration
	require 'yaml'
	ENV = YAML::load(File.open(File.expand_path("../../config/config.yml", __FILE__)))
	SETTINGS = YAML::load(File.open(File.expand_path("../../config/settings.yml", __FILE__)))

	desc 'sync [DIRECTORY]', 'Begin syncing a directory (remote changes will be overwritten)'
	def sync (directory)

		# Connect to Bluetrain.io
		connect

		# Define the listening process
		listener = Listen.to("#{directory}/includes","#{directory}/templates","#{directory}/plugins", polling_fallback_message: false) do |modified, added, removed|
		#  	begin
			  unless modified.empty?
			  	modified.each do |file| 
			  		bfh = BluetrainFileHelper.new(file)
			  		puts file
			  		unless /\/plugins\// =~ File.dirname(file)
			  			@bt_net.update(bfh.name, bfh.content, bfh.kind)
			  		else
			  			widget_name = File.dirname(file).split('/').last

			  			if bfh.name == "settings.json"
			  				@bt_net.configure_widget widget_name, bfh.content
			  			else
			  				@bt_net.update_widget(widget_name, bfh.content, bfh.device)
			  			end
			  		end
			  	end
			  end
			  unless added.empty?
			  	added.each do |file| 
			  		bfh = BluetrainFileHelper.new(file)
			  		puts file
			  		unless /\/plugins\// =~ File.dirname(file)
			  			@bt_net.create(bfh.name, bfh.content, bfh.kind)
			  		else
			  			widget_name = File.dirname(file).split('/').last

			  			if bfh.name == "settings.json"
			  				@bt_net.create_widget widget_name, bfh.content
			  				@bt_net.configure_widget widget_name, bfh.content
			  			else
			  				@bt_net.update_widget(widget_name, bfh.content, bfh.device)
			  			end
			  		end
			  	end
			  end
			  unless removed.empty?
			  	removed.each do |file| 
			  		unless  /\/plugins\// =~ File.dirname(file)
			  			bfh = BluetrainFileHelper.new(file)
			  			@bt_net.delete(bfh.name)
			  		else 
			  			bfh = BluetrainFileHelper.new(file, 'widget')
			  			widget_name = File.dirname(file).split('/').last
			  			@bt_net.delete_widget_device_template(widget_name, bfh.device)
			  		end
			  	end
			  end
			#rescue
			#	puts "An error has occurred with syncing.  Your last change has not been saved."
			#end
		end

		# Start listening
		puts "Syncing #{directory} up to Bluetrain.io - press ctrl + c to quit"
		listener.start
		
		# Handle ctrl^c gracefully
		begin
			sleep
		rescue SignalException
			puts "Exiting..."
		end
	end

	desc 'pull [DIRECTORY]', 'Pull down all templates from the server (local changes will be overwritten)'
	def pull (directory)

		# Connect to Bluetrain.io
		connect

		# Create directory structure
		FileUtils.mkdir_p("#{directory}/templates")
		FileUtils.mkdir_p("#{directory}/includes")
		FileUtils.mkdir_p("#{directory}/plugins")

		# Get a list of remote templates
		template_json = @bt_net.get_templates
		widget_json = @bt_net.get_widgets

		unless template_json.nil?
			templates = JSON.parse template_json

			# Create a file representing each template
			templates.each {|template| BluetrainFileHelper.write_template directory, template['presentation_layer_template']}
		end

		unless widget_json.nil?
			widgets = JSON.parse widget_json

			widgets.each do |widget|
				widget = widget["widget"]
				FileUtils.mkdir_p("#{directory}/plugins/#{widget['name']}")
				BluetrainFileHelper.write_widget_settings(directory, widget)
				device_templates = JSON.parse @bt_net.get_widget_device_templates(widget['name'])
				device_templates.each do |device_template|
					BluetrainFileHelper.write_device_template("#{directory}/plugins/#{widget['name']}", device_template['device_template'])
				end
			end
		end
	end

	desc 'push [DIRECTORY]', 'Push all templates from the specified diretory to the server (remote changes will be overwritten)'
	def push (directory)

		# Connect to Bluetrain.io
		connect

		# Get a list of remote templates
		template_json = @bt_net.get_templates
		widget_json = @bt_net.get_widgets

		unless template_json.nil? || widget_json.nil?

			# Create an array of template titles
			templates = JSON.parse template_json
			widgets = JSON.parse widget_json

			# Widget templates can share the names of other templates, filter them out
			widgets.collect! {|widget| widget['widget']['name']}
			widget_templates = templates.select {|template| template['presentation_layer_template']['widget_id'] != nil}
			widget_templates.collect! {|template| template['presentation_layer_template']['title']}
			templates.select! {|template| template['presentation_layer_template']['widget_id'] == nil}
			templates.collect! {|template| template['presentation_layer_template']['title']}

			# Templates
			# For each file in the specified directory (which ends in .html)
			Dir.chdir("#{directory}/templates") do 
				Dir.glob('*.html').each do |file|
					bfh = BluetrainFileHelper.new(file, 'template')

					# Determine if the file exists remotely, if so PUT else POST
					unless (index = templates.index(File.basename(file, '.*'))).nil?
						templates.delete_at(index)
						@bt_net.update(File.basename(file, '.*'), bfh.content, 'template')
					else
						@bt_net.create(File.basename(file, '.*'), bfh.content, 'template')
					end
				end
			end	

			# Includes
			Dir.chdir("#{directory}/includes") do 
				Dir.glob('*').each do |file|
					bfh = BluetrainFileHelper.new(file, 'include')

					# Determine if the file exists remotely, if so PUT else POST
					unless (index = templates.index(file)).nil?
						templates.delete_at(index)
						@bt_net.update(file, bfh.content, 'include')
					else
						@bt_net.create(file, bfh.content, 'include')
					end
				end
			end	

			# Widgets
			Dir.chdir("#{directory}/plugins") do
				Dir.glob('*').each do |folder|
					device_templates = ['default', 'preview', 'publish', 'edit']
					Dir.chdir(folder) do
						# Push Settings
						bfh = BluetrainFileHelper.new('settings.json')
						if widgets.index(folder).nil?
							@bt_net.create_widget folder, File.read('settings.json')
						end
						@bt_net.configure_widget folder, bfh.content

						# Push Templates
						Dir.glob('*').each do |file|
							unless file == "settings.json"
								bfh = BluetrainFileHelper.new(file, 'widget')
								@bt_net.update_widget(folder, bfh.content, bfh.device)
								device_templates.delete(bfh.device)
							end
						end

						device_templates.each do |dt|
							@bt_net.delete_widget_device_template(folder, dt)
						end
					end
				end
			end

			# Delete removed files
			#templates.each {|template| @bt_net.delete(template)}
			#widget_templates.each {|template| @bt_net.delete(template)}

			puts 'Push completed.'
		end
	end

	private

		# Connect to Bluetrain.io
		# If a config/settings.yml exists, attempt to use the credentials stored there
		# If a config file doesn't exist, prompt the user.
		def connect

			# Default to production for end users
			env = (SETTINGS && SETTINGS['env']) ? SETTINGS['env'] : 'production'
			@bt_net = BluetrainNetwork.new(env)

			if !SETTINGS || SETTINGS['email'].nil? || SETTINGS['token'].nil?
				user_email = ask "Email: "

				password = $stdin.noecho do
					ask("Password: ")
				end
				puts ""
				
				if @bt_net.authenticate(user_email, password)

	 				@bt_net.set_website(select_website(@bt_net.get_websites))

	 				# Persist settings & token to disk if the user asks
					if ask("Remember credentials (y/n)?") == 'y'
						File.open('./config/settings.yml', 'w') {|f| f.write @bt_net.get_auth_settings.to_yaml }
					end
				else
					abort("Unable to authenticate.")
				end
			else
				@bt_net.set_stored_credentials(SETTINGS['email'], SETTINGS['token'])
				@bt_net.set_website(SETTINGS['website'])
			end
		end

		def select_website (website_list)
			unless website_list.nil?
				website_list = JSON.parse website_list
				website_list.each {|name, id| puts "#{name} (ID: #{id})" }
			end

			ask("Please enter the ID of the website to use: ")
		end
end