class BluetrainFileHelper
	attr_reader :name, :kind, :content

	def initialize (file_path, kind = nil)
		unless kind == 'widget'

      # Catch errors reading content for deleted files
      begin
			 @content = File.read(file_path)
      rescue
        
      end
		end

		# Determine the 'kind' of resource this document is based on path
		# Currently support 'kind's are: template, include
		if kind.nil?
			if  /\/includes$/ =~ File.dirname(file_path)
				@kind = 'include'
			elsif /\/plugins\// =~ File.dirname(file_path)
				@kind = 'widget'
			else 
				@kind = 'template'
			end
		else 
			@kind = kind
		end

		@name = @kind.eql?('template') ? File.basename(file_path, '.*') : File.basename(file_path)
	end

	# Return the content in the <head> tag of a template, or 
	# an empty string if the document's kind indicates that it does not contain HTML
	def head_content
		if @kind == "template"
			@content.scan(/<head>(.*)<\/head>/imu).flatten.first
		else 
			''
		end
	end

	# Return the content of the <body> tag of a template, or
	# an empty string if the document's kind indicates that it does not contain HTML
	def body_content
		if @kind == "template"
			@content.scan(/<body>(.*)<\/body>/imu).flatten.first
		else
			@content
		end
	end

	# Return the device (for widgets) if applicable, otherwise false
	def device
		if @kind == "widget"
			case @name
				when "preview.html"
					"preview"
				when "edit.html"
					"edit"
				when "default.html"
					"default"
				when "publish.html"
					"publish"
			end
		else
			false
		end
	end

	def self.write_template (directory, template)
		case template['kind']
			when "template" 
				File.open("#{directory}/templates/#{template['title']}.html", 'w') {|f|
					f.write(template['default_content'])
				}

			when "include"
				File.open("#{directory}/includes/#{template['title']}", 'w') {|f|
					f.write(template['default_content'])
				}

			# Handle Widgets Seperately
		end			
	end

	def self.write_device_template (directory, template)
		File.open("#{directory}/#{template['device']}.html", 'w') {|f|
				f.write(template['content'])
		}
	end

	def self.write_widget_settings (directory, widget)
		File.open("#{directory}/plugins/#{widget['name']}/settings.json", 'w') {|f|
				f.write("{\"enabled\":#{widget['is_enabled']}}")
		}
	end		

end