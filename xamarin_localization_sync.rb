#encoding: utf-8
require 'xmlsimple'
require 'fileutils'
require 'yaml'


module XamarinLocalizationSync

	APP_NAME = 'xamarin_localization_sync'
	SETTINGS_FILE_NAME = 'settings.yml'

	def load_settings
		settings_file_path = File.dirname(__FILE__) + '/' + SETTINGS_FILE_NAME
		if !ENV['OCRA_EXECUTABLE'].nil?
			settings_file_path = File.dirname(ENV['OCRA_EXECUTABLE']) + '/' + SETTINGS_FILE_NAME
		end

		settings = nil
		if File.exists?(settings_file_path)
			settings = YAML.load_file(settings_file_path)
		else
			dir = File.dirname(__FILE__)
			settings = {
				solution_directory: dir, project_name: 'AppName', resource_directory: dir + '/Resources', 
				resource_file_name: 'AppResources', target_dir: dir
			}
			File.open(settings_file_path, 'w') {|f| f.write settings.to_yaml } 
			raise ArgumentError, "You must update settings.yml => #{settings_file_path}"
		end
		settings
	end

	class LocalizationGenerator

		def initialize
			settings = load_settings
			if settings.nil?
				raise ArgumentError, 'You must input settings.yml'
			end
			@soulution_dir = settings[:solution_directory]
			@project_name = settings[:project_name].nil? ? File.basename(@soulution_dir) : settings[:project_name]

			@resource_dir = settings[:resource_directory]
			@target_file_name = settings[:resource_file_name]
			@result_dir = settings[:target_dir]
			@contents = {}
		end

		def read_resx_files
			file_names = []
			Dir.entries(@resource_dir).each do |file_name|
				file_names << file_name if file_name =~ /#{@target_file_name}.*\.resx/
			end
			file_names.each do |file_name|
				content = ''
				doc = XmlSimple.xml_in(@resource_dir + '/' + file_name)
				
				locale_name = File.basename(file_name, '.resx').sub(@target_file_name, '').gsub('.', '')
				if locale_name.empty?
					@contents['default'] = doc['data']
				else
					@contents[locale_name] = doc['data']
				end
			end
		end

		def write_android_localizations
			target_dir = @result_dir + '/android'
			if File.exist? target_dir
				FileUtils.rm_rf(target_dir)
			end
			FileUtils::mkdir_p target_dir

			@contents.each do |k, v|
				locale_name = k.sub('-', '-r')
				dirname = 'values'
				if k != 'default'
					dirname += "-#{locale_name}"
				end
				data_list = v.map do |data|
					{'@name' => data['name'], 'value' => data['value'].first}
				end

				FileUtils::mkdir_p target_dir + '/' + dirname
				doc = XmlSimple.xml_out({'string' => data_list}, "AttrPrefix" => true, 
										"RootName" => "resources",
	                                  "ContentKey" => "value")
				File.open("#{target_dir}/#{dirname}/Strings.xml", "w:utf-8") do |f|
					f.write(doc)
				end
			end

		end

		def write_ios_localizations
			target_dir = @result_dir + '/ios'
			if File.exist? target_dir
				FileUtils.rm_rf(target_dir)
			end
			FileUtils::mkdir_p target_dir

			@contents.each do |k, v|
				locale_name = k.sub('-', '_')
				if locale_name[0, 2] == 'pt'
					if locale_name == 'pt'
						locale_name = 'pt-BR' 
					else
						locale_name = 'pt-PT' 
					end
				end
				
				data_list = v.map do |data|
					"\"#{data['name']}\" = \"#{data['value'].first}\";"
				end

				dirname = locale_name[0, 2] + '.lproj'
				dirname = 'Base.lproj' if locale_name == 'default'

				FileUtils::mkdir_p target_dir + '/' + dirname
				File.open("#{target_dir}/#{dirname}/Localizable.strings", "w:utf-8") do |f|
					f.write(data_list.join("\n"))
				end
			end
		end

		def push_files
			aos_result_dir = @result_dir + '/android'
			ios_result_dir = @result_dir + '/ios'
			aos_target_dir = "#{@soulution_dir}/#{@project_name}.Droid/Resources"
			ios_target_dir = "#{@soulution_dir}/#{@project_name}.iOS/Resources"
			FileUtils.copy_entry(aos_result_dir, aos_target_dir)
			FileUtils.copy_entry(ios_result_dir, ios_target_dir)
		end

	end

end

include XamarinLocalizationSync

lg = LocalizationGenerator.new
lg.read_resx_files
lg.write_android_localizations
lg.write_ios_localizations
lg.push_files
