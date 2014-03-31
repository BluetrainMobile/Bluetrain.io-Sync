class BluetrainFileHelper

	def initialize (file_path)
		@content = File.read(file_path)
	end

	def head_content
		@content.scan(/<head>(.*)<\/head>/imu).flatten.first
	end

	def body_content
		@content.scan(/<body>(.*)<\/body>/imu).flatten.first
	end

	def self.write_template (directory, template)
		File.open("#{directory}/#{template['title']}.html", 'w') {|f|
			f.write("<head>#{template['default_head_content']}</head><body>#{template['default_body_content']}</body>")
		}
	end

end