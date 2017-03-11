require 'deep_clone'
require_relative 'spec_target_configuration_dsl_12X'

module StructCore
	class SpecTargetDSL12X
		def initialize
			@target = nil
			@type = nil
			@raw_type = nil
			@profiles = []
			@project_configurations = []
			@project_base_dir = nil
		end

		attr_accessor :project_configurations
		attr_accessor :project_base_dir
		attr_accessor :target

		def type(type)
			@type = type
			@type = type.to_s if type.is_a?(Symbol)
			# : at the start of the type is shorthand for 'com.apple.product-type.'
			if @type.start_with? ':'
				@type[0] = ''
				@raw_type = type
				@type = "com.apple.product-type.#{type}"
			else
				@raw_type = type
			end

			@profiles << @raw_type
			@target.type = @type
		end

		def profile(profile)
			@profiles << profile
		end

		def platform(platform)
			# TODO: Add support for 'tvos', 'watchos'
			unless %w(ios mac).include? platform
				puts Paint["Warning: Target #{target_name} specifies unrecognised platform '#{platform}'. Ignoring...", :yellow]
				return
			end

			@profiles << "platform:#{platform}"
		end

		def configuration(name = nil, &block)
			if name.nil?
				dsl = StructCore::SpecTargetConfigurationDSL12X.new
				dsl.configuration = StructCore::Specfile::Target::Configuration.new nil, {}, []
				dsl.instance_eval(&block)

				config = dsl.configuration
				config.profiles = @profiles
				@target.configurations = @project_configurations.map { |project_config|
					target_config = DeepClone.clone config
					target_config.name = project_config.name
					target_config
				}
			else
				dsl = StructCore::SpecTargetConfigurationDSL12X.new
				dsl.configuration = StructCore::Specfile::Target::Configuration.new name, {}, []
				dsl.instance_eval(&block)

				config = dsl.configuration
				config.profiles = @profiles

				@target.configurations << config
			end
		end

		def source_dir(path)
			@target.source_dir << File.join(@project_base_dir, path)
		end

		def i18n_resource_dir(path)
			@target.res_dir << File.join(@project_base_dir, path)
		end

		def system_reference(reference)
			if reference.end_with? '.framework'
				@target.references << StructCore::Specfile::Target::SystemFrameworkReference.new(reference.sub('.framework', ''))
			else
				@target.references << StructCore::Specfile::Target::SystemLibraryReference.new(reference)
			end
		end

		def target_reference(reference)
			@target.references << StructCore::Specfile::Target::TargetReference.new(reference)
		end

		def framework_reference(reference, settings = nil)
			@target.references << StructCore::Specfile::Target::LocalFrameworkReference.new(reference, settings)
		end

		def project_framework_reference(&block)

		end

		def respond_to_missing?(_, _)
			true
		end

		# rubocop:disable Style/MethodMissing
		def method_missing(_, *_)
			# Do nothing if a method is missing
		end
		# rubocop:enable Style/MethodMissing
	end
end