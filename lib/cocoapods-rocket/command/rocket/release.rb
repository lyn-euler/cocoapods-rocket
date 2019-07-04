require 'cocoapods-rocket/utility/configuration'
require 'cocoapods-rocket/pod/version'
require 'cocoapods-rocket/utility/git'
require 'json'
require 'colored2'

module Pod
  class Command
    class Rocket
      class Release < Rocket
        self.summary = 'release rocket project.'

        self.description = <<-DESC
          push pod  lib, if version is nil will increase last_version.
          lint & dump version & git tag & git push & git merge to master & git push & repo push
        DESC

        # self.arguments = 'NAME'
        #

        def self.options
          [
              ['--to-version=TO_VERSION', 'the dump version of the podspec']
          ].concat(super)
        end

        def initialize(argv)

          @configuration = Rocket::Utility::Configuration.read_pod_rocket_config(Pathname.pwd)
          read_pod_spec
          @to_version = argv.option('to-version', nil)
          super
        end

        def validate!
          super

        end

        def run
          @configuration.repos.each do |repo|
            system("pod repo update #{repo}")
          end
          raise "[pod-rocket]::ERROR lint end" unless pod_lint
          bump_version(@to_version)
          push_changes_and_tag
          pod_repo_push
        end


        private
        def read_pod_spec

          files = Pathname.glob(Pathname.pwd + "#{@configuration.podspec_name}.podspec{.json,}")
          files.each do |path|
             @podspec_path = path
             @podspec = Pod::Specification.from_file(path)
             return
          end
          raise 'Unable to find a podspec file in the working ' \
                'directory' \
                "at: #{Pathname.pwd}"
        end


        def pod_lint
          puts "🚀[pod-rocket]:: ====begin lint====".green
          system("#{@configuration.lint_cmd}")
        end

        def pod_repo_push
          puts "🚀[pod-rocket]:: ====begin pod repo push====".green
          @configuration.push_cmds.each do |push_cmd|
            raise "❌❌❌#{push_cmd} 执行出错❌❌❌" unless system("#{push_cmd}")
          end
        end


        def bump_version(to_version = nil)
          puts "🚀[pod-rocket]:: ====begin bump version ===="

          raise 'undefined to version' if @podspec.version.nil?
          puts "[pod-rocket]::先前的版本#{@podspec.version.version}".green
          if to_version.nil?
            @podspec.version = @podspec.version.rocket_patch_bump
          else
            @podspec.version = Pod::Version.new(to_version)
          end
          puts "[pod-rocket]::bump后的版本号#{@podspec.version.version}".green
          update_podspec(true)
        end


        def update_podspec(require_variable_prefix)
          puts "🚀[pod-rocket]:: ====begin update podspec file: .version  ===="
          version_var_name = 'version'
          variable_prefix = require_variable_prefix ? /\w\./ : //
          _version_regex = /^(?<begin>[^#]*#{variable_prefix}#{version_var_name}\s*=\s*['"])(?<value>(?<major>[0-9]+)(\.(?<minor>[0-9]+))?(\.(?<patch>[0-9]+))?(?<appendix>(\.([0-9]|[a-z]|[A-Z])+)*)?(-(?<prerelease>(.+)))?)(?<end>['"])/i
          _podspec_content = File.read(@podspec_path)

          puts "[pod-rocket]::开始操作podspec文件"
          _version_match = _version_regex.match(_podspec_content)
          raise "Could not find version in podspec content '#{@podspec_content}'" if _version_match.nil?
          updated_podspec_content = _podspec_content.gsub(_version_regex, "#{_version_match[:begin]}#{@podspec.version.version}#{_version_match[:end]}")
          File.open(@podspec_path, "w") { |file| file.puts(updated_podspec_content) }
          puts "[pod-rocket]::操作 podspec 文件version:#{@podspec.version.version}变更成功"
        end


        def push_changes_and_tag
          puts "🚀[pod-rocket]::begin commit change & tag".green
          curr_branch = Rocket::Utility::Git.curr_local_branch_name
          puts "[pod-rocket]:: current branch is #{curr_branch}."
          if Rocket::Utility::Git.any_diff?
            raise "[pod-rocket]:: git commit error" unless Rocket::Utility::Git.commit_all("pod-rocket(release):podspec version bump to #{@podspec.version.version}")
            raise "[pod-rocket]:: git merge  master branch error" unless Rocket::Utility::Git.merge('master')
            raise "[pod-rocket]:: git commit error" unless Rocket::Utility::Git.commit_all("pod-rocket(release):merge branch 'master' to #{curr_branch}")
            raise "[pod-rocket]:: git pull master branch error" unless Rocket::Utility::Git.push_to_branch("#{curr_branch}")

            if curr_branch != 'master'
              puts "🚀[pod-rocket]::#{@configuration.podspec_name} merge branch '#{curr_branch}' to branch 'master'. "
              raise "[pod-rocket]:: git checkout master branch error" unless Rocket::Utility::Git.checkout('master')
              raise "[pod-rocket]:: git pull master branch error" unless Rocket::Utility::Git.pull('master')
              raise "[pod-rocket]:: git merge error" unless Rocket::Utility::Git.merge(curr_branch)
              raise "[pod-rocket]:: git commit error" unless Rocket::Utility::Git.commit_all("pod-rocket(release):merge branch #{curr_branch} to 'master'")
              raise "[pod-rocket]:: git pull master branch error" unless Rocket::Utility::Git.push_to_branch('master')
            end

            # 合并 master 分支到 develop 分支
            if Rocket::Utility::Git.remote_branch_exit?('develop')
              Rocket::Utility::Git.checkout('develop')
              Rocket::Utility::Git.pull('develop')
              Rocket::Utility::Git.merge('master')
              Rocket::Utility::Git.commit_all("pod-rocket(release):merge branch 'master' to 'develop'")
              Rocket::Utility::Git.push_to_branch('develop')
            end
          end
          raise "[pod-rocket]:: git merge error" unless Rocket::Utility::Git.add_and_push_tag(@podspec.version.version)
        end

      end
    end
  end
end
