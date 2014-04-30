class BluetrainFileHelper
	attr_reader :name, :kind, :content

	def initialize (file_path, kind = nil)
		@content = File.read(file_path)

		# Determine the 'kind' of resource this document is based on path
		# Currently support 'kind's are: template, include
		if kind.nil?
			@kind = /\/includes$/ =~ File.dirname(file_path) ? 'include' : 'template'
		else 
			@kind = kind
		end

		@name = @kind.eql?('include') ? File.basename(file_path) : File.basename(file_path, '.*')
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
					f.write(template['default_content'])
				}

			when "include"
				File.open("#{directory}/includes/#{template['title']}", 'w') {|f|
					f.write(template['default_content'])
				}
		end			
	end

end