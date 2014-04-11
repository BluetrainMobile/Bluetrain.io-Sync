class Bluetrain < Thor

	# External Requirements
	require 'rubygems' 
	require 'bundler/setup' 
	require 'listen'
	require 'io/console'
	require 'json'

	# Internal Requirements
	require 'bluetrain_network'
	require 'bluetrain_file_helper'

	# Configuration
	require 'yaml'
	ENV = YAML::load(File.open("./config/config.yml"))
	SETTINGS = YAML::load(File.open("./config/settings.yml"))

	desc 'sync [DIRECTORY]', 'Begin syncing a directory (remote changes will be overwritten)'
	def sync (directory)

		# Connect to Bluetrain.io
		connect

		# Define the listening process
		listener = Listen.to(directory, polling_fallback_message: false) do |modified, added, removed|
		  unless modified.empty?
		  	modified.each do |file| 
		  		bfh = BluetrainFileHelper.new(file)
		  		puts file
		  		@bt_net.update(bfh.name, bfh.head_content, bfh.body_content, bfh.kind)
		  	end
		  end
		  unless added.empty?
		  	added.each do |file| 
		  		bfh = BluetrainFileHelper.new(file)
		  		puts file
		  		@bt_net.create(bfh.name, bfh.head_content, bfh.body_content, bfh.kind)
		  	end
		  end
		  unless removed.empty?
		  	removed.each do |file| 
		  		@bt_net.delete(bfh.name)
		  	end
		  end
		end

		# Start listening
		puts "Syncing #{directory} up to Bluetrain.io - press ctrl + c to quit"
		listener.start
		sleep
	end

	desc 'pull [DIRECTORY]', 'Pull down all templates from the server (local changes will be overwritten)'
	def pull (directory)

		# Connect to Bluetrain.io
		connect

		# Get a list of remote templates
		template_json = @bt_net.get_templates

		unless template_json.nil?
			templates = JSON.parse template_json

			# Create a file representing each template
			templates.each {|template| BluetrainFileHelper.write_template directory, template['presentation_layer_template']}
		end
	end

	desc 'push [DIRECTORY]', 'Push all templates from the specified diretory to the server (remote changes will be overwritten)'
	def push (directory)

		# Connect to Bluetrain.io
		connect

		# Get a list of remote templates
		template_json = @bt_net.get_templates

		unless template_json.nil?

			# Create an array of template titles
			templates = JSON.parse template_json
			templates.collect! {|template| template['presentation_layer_template']['title']}

			# Templates
			# For each file in the specified directory (which ends in .html)
			Dir.chdir("#{directory}/templates") do 
				Dir.glob('*.html').each do |file|
					bfh = BluetrainFileHelper.new(file)

					# Determine if the file exists remotely, if so PUT else POST
					unless templates.index(File.basename(file, '.*')).nil?
						@bt_net.update(File.basename(file, '.*'), bfh.head_content, bfh.body_content, 'template')
					else
						@bt_net.create(File.basename(file, '.*'), bfh.head_content, bfh.body_content, 'template')
					end
				end
			end	

			# Includes
			Dir.chdir("#{directory}/includes") do 
				Dir.glob('*').each do |file|
					bfh = BluetrainFileHelper.new(file)

					# Determine if the file exists remotely, if so PUT else POST
					unless templates.index(file).nil?
						@bt_net.update(file, '', bfh.body_content, 'include')
					else
						@bt_net.create(file, '', bfh.body_content, 'include')
					end
				end
			end	

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