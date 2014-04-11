class BluetrainFileHelper
	attr_reader :name, :kind

	def initialize (file_path)
		@content = File.read(file_path)

		# Determine the 'kind' of resource this document is based on path
		# Currently support 'kind's are: template, include
		if /\/includes$/ =~ File.dirname(file_path) 
			@kind = "include"
			@name =	File.basename(file_path)
		else
			@kind = "template"
			@name = File.basename(file_path, '.*')
		end

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

	def self.write_template (directory, template)
		case template['kind']
			when "template" 
				File.open("#{directory}/templates/#{template['title']}.html", 'w') {|f|
					f.write("<head>#{template['default_head_content']}</head><body>#{template['default_body_content']}</body>")
				}

			when "include"
				File.open("#{directory}/includes/#{template['title']}", 'w') {|f|
					f.write(template['default_body_content'])
				}
		end			
	end

end