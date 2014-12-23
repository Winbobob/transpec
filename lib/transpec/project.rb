# coding: utf-8

require 'transpec/rspec_version'
require 'bundler'
require 'English'

module Transpec
  class Project
    attr_reader :path

    def initialize(path = Dir.pwd)
      @path = path
    end

    def basename
      File.basename(path)
    end

    def using_bundler?
      File.exist?(gemfile_lock_path)
    end

    def depend_on_rspec_rails?
      return @depend_on_rspec_rails if instance_variable_defined?(:@depend_on_rspec_rails)
      return @depend_on_rspec_rails = false unless using_bundler?
      @depend_on_rspec_rails = dependency_gems.any? { |gem| gem.name == 'rspec-rails' }
    end

    def rspec_version
      @rspec_version ||= RSpecVersion.new(fetch_rspec_version)
    end

    def with_bundler_clean_env
      if defined?(Bundler) && using_bundler?
        Bundler.with_clean_env do
          # Bundler.with_clean_env cleans environment variables
          # which are set after bundler is loaded.
          yield
        end
      else
        yield
      end
    end

    private

    def dependency_gems
      @dependency_gems ||= begin
        gemfile_lock_content = File.read(gemfile_lock_path)
        lockfile = Bundler::LockfileParser.new(gemfile_lock_content)
        lockfile.specs
      end
    end

    def gemfile_lock_path
      @gemfile_lock_path ||= File.join(path, 'Gemfile.lock')
    end

    def fetch_rspec_version
      if using_bundler?
        rspec_core_gem = dependency_gems.find { |gem| gem.name == 'rspec-core' }
        rspec_core_gem.version
      else
        require 'rspec/core/version'
        RSpec::Core::Version::STRING
      end
    end
  end
end
