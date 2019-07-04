require 'cocoapods-rocket/utility/configuration'
require 'cocoapods-rocket/utility/podfile'
require 'cocoapods-rocket/utility/lockfile'
require 'cocoapods-rocket/utility/git'

module Pod
  class Command
    class Rflow
      class Release < Rflow
        self.summary = 'release flow podfile '

        self.description = <<-DESC
          create .pod-rocket.json file for project
        DESC

        # self.arguments = 'NAME'
        #

        # def self.options
        #   [
        #       ['--target-branch=BRANCH', 'the URL of the .pod-rocket.json template'],
        #       # ['--use-default', 'use default config']
        #   ].concat(super)
        # end

        def initialize(argv)

          # @template_url = argv.option('template-url', DEFAULT_TEMPLATE_URL)
          @root_dir = Pathname.pwd
          @podfile = Rocket::Utility::Podfile.new(Pathname.pwd+'Podfile')
          raise "not find PodfileTARGET_BRANCH at current dir" if @podfile.nil?

          @lockfile = Rocket::Utility::Lockfile.read_from(Pathname.pwd+'Podfile.lock')
          raise "not find Podfile.lock at current dir" if @lockfile.nil?

          @git_info_need_release_pods = @podfile.need_release_pods
          @podfile_need_release_root_pods = @podfile.need_release_pods.map { |dependency| # Pod::Dependency
            dependency.root_name
          }.uniq

          @need_release_pods = []
          @podfile_need_release_root_pods.each do |root_pod|
            dependency_root_pods = @lockfile.all_root_dependencies_for_pod(root_pod) || []
            dependency_root_pods = dependency_root_pods.select do |root_pod|
              @podfile_need_release_root_pods.include?(root_pod)
            end
            @need_release_pods << {:root_pod => root_pod, :dependencies => dependency_root_pods}
          end
          puts "🚀[pod-gflow]::🏆release #{@podfile_need_release_root_pods}"
          super
        end

        def validate!
          super

        end

        def run

          begin
            release_all
            push_podfile
          end

        end


        def release_all
          while !@podfile_need_release_root_pods.empty? do
            pods = can_release_pods
            pods_keys = []
            pods.each do |pod|
              pods_keys << pod[:root_pod]
              unless release_pod(pod[:root_pod])
                raise "[pod-rocket]❌❌ #{pod[:root_pod]} 发布失败 ❌❌"
              end
              @need_release_pods.delete(pod)
              @podfile_need_release_root_pods.delete(pod[:root_pod])
              podfile_modify(pod[:root_pod])
            end
            @need_release_pods.each do |item|
              item[:dependencies].delete_if do |pod|
                pods_keys.include?(pod)
              end
            end
            puts "#{@podfile_need_release_root_pods}"
          end

        end

        def can_release_pods
          @need_release_pods.select {|pod| pod[:dependencies].count == 0}
        end

        def release_pod(root_pod)
          release_dir = Pathname.new(@root_dir+'.pod_release_temp_dir')

          raise "[rflow-release]::创建临时文件夹失败 'mkdir #{release_dir}'" unless File.exist?(release_dir) || system("mkdir #{release_dir}")
          system("rm -rf '#{release_dir}'")
          @git_info_need_release_pods.each do |dependency|
            if dependency.root_name == root_pod
              puts "releasing #{root_pod}"

              git = dependency.external_source[:git]
              curr_branch = dependency.external_source[:branch]

              Rocket::Utility::Git.clone(git, root_pod)
              cmd = %Q{
              git clone #{git} '#{release_dir}/#{root_pod}'
              cd #{release_dir}/#{root_pod}
              git checkout #{curr_branch}
              pod rocket init --use-default=true
              pod rocket release
              }
              raise "#{root_pod}::发布失败" unless system(cmd)

              system("rm -rf '#{release_dir}'")
            end
          end
          system("cd '#{@root_dir}'")
          true
        end

        def podfile_modify(root_name)
          puts "🚀[pod-gflow] modify podfile #{root_name}".green
          dependencies = @podfile.need_release_pods.select {|item| item.root_name == root_name}
          text = File.read(@podfile.file_path)
          dependencies.each do |pod|
            text.each_line { |line|
              if line.include?("'#{pod.name}'") || line.include?("\"#{pod.name}\"")
                new_line = line.gsub(%r{,\s*:git\s*=>\s*['|"][\w|\S]+['|"]},'')
                new_line = new_line.gsub(%r{,\s*:branch\s*=>\s*['|"][\w|\S]+['|"]},'')
                text = text.gsub("#{line}", "#{new_line}")
              end
            }
          end
          File.open(@podfile.file_path, 'w') do |file|
            file.puts text
          end
        end

        def push_podfile
          if Rocket::Utility::Git.any_diff?('Podfile*')
            curr_branch = Rocket::Utility::Git.curr_local_branch_name
            cmd = %Q{
            set -e
            git add Podfile*
            git commit -m 'rocket(rflow-merge): update podfile & podfile.lock'
            git push
            }
            system(cmd)
          end
        end

      end
    end
  end
end
