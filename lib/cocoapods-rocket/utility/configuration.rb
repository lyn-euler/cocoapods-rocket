class Pod::Command::Rocket
  module Utility
    class Configuration

      def self.release_configuration_file_name
        '.pod-rocket.json'.freeze
      end

      @name
      @sources = ['git@git.2dfire.net:ios/cocoapods-spec.git']
      @target_repos = ['master']
      @use_libraries = true
      @allow_warnings = true
      @verbose = true
      @use_modular_headers = true

      def  initialize(config)
        @name = config["name"]
        @sources = config["sources"] if config["sources"]
        @target_repos = config["targetRepos"] unless config["targetRepos"].nil? || config["targetRepos"].empty?
        @use_libraries = config["useLibraries"] unless config["useLibraries"].nil?
        @allow_warnings = config["allowWarnings"] unless config["allowWarnings"].nil?
        @verbose = config["verbose"] unless config["verbose"].nil?
        @use_modular_headers = config["onlyError"] unless config["useModularHeaders"].nil?
      end

      public

      def self.read_from_path(path)
        if path
          json = File.read(path)
          return read_from_json(json)
        end
      end

      def self.read_from_json(json)
        return Configuration.new(JSON.parse(json)) if json
      end

      def lint_cmd
        validate!
        cmd = "pod lib lint #{@name}.podspec"
        cmd_append_params(cmd)
        cmd
      end

      def podspec_name
        @name
      end

      def repos
        @target_repos
      end

      def push_cmds
        cmds = []
        @target_repos.each do |repo|
          cmd = push_repo_cmd(repo)
          cmds.append(cmd) if cmd
        end
        cmds
      end

      def self.read_pod_rocket_config(dir)
        files = Pathname.glob(dir + "#{release_configuration_file_name}")
        if files.count.zero?
          raise 'Unable to find a .pod-rocket.json in the working ' \
                'directory' \
                "at: #{dir}"
        end
        files.each do |path|
          puts "[pod-rocket]:: read configuration from #{path}".green
          return read_from_path(path)
        end
        raise 'parse pod-rockit.json to configuration error' if @configuration.nil?
      end

      private


      def push_repo_cmd(repo)
        raise "repo can't be nil" if repo.nil?
        validate!
        cmd = "pod repo push '#{repo}' #{@name}.podspec"
        cmd_append_params(cmd)
        cmd
      end

      def cmd_append_params(cmd)
        raise 'cmd is nil' if cmd.nil?
        unless @sources.nil? || @sources.empty?
          cmd << " --sources="
          @sources.each do |source|
            cmd << "'#{source}'"
          end
        end
        cmd << " --allow-warnings" if @allow_warnings
        cmd << " --use-libraries" if  @use_libraries
        cmd << " --verbose" if @verbose
        cmd << " --use-modular-headers" if @use_modular_headers
      end

      def validate!
        raise "@name can't be nil" if @name.nil?
        true
      end

    end
  end
end
