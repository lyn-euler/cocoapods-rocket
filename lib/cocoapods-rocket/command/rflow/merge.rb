require 'cocoapods-rocket/utility/git'

module Pod
  class Command
    class Rflow
      class Merge < Rflow
        self.summary = 'release flow podfile '

        self.description = <<-DESC
          create .pod-rocket.json file for project
        DESC

        self.arguments = 'TARGET_BRANCH'
        #

        def self.options
          [
              ['--target-branch=TARGET_BRANCH', 'the target branch'],
          ].concat(super)
        end

        def initialize(argv)
          @target_branch = argv.option('target-branch', 'master')
          @root_dir = Pathname.pwd
          @podfile = Rocket::Utility::Podfile.new(Pathname.pwd+'Podfile')
          raise "not find Podfile at current dir" if @podfile.nil?

          @lockfile = Rocket::Utility::Lockfile.read_from(Pathname.pwd+'Podfile.lock')
          raise "not find Podfile.lock at current dir" if @lockfile.nil?

          @git_info_need_release_pods = @podfile.need_merge_pods(@target_branch)
          @podfile_need_release_root_pods = @git_info_need_release_pods.map { |dependency| # Pod::Dependency
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
          puts "🚀[pod-gflow]::🏆merge #{@podfile_need_release_root_pods}"

          super
        end

        def validate!
          super

        end

        def run
          merge_all
          system("pod update")
          push_podfile
        end


        def merge_all
          while !@podfile_need_release_root_pods.empty? do
            pods = can_release_pods
            pods_keys = []
            pods.each do |pod|
              pods_keys << pod[:root_pod]
              unless merge_pod(pod[:root_pod])
                raise "[pod-rocket]❌❌ #{pod[:root_pod]} 合并失败 ❌❌"
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

        def merge_pod(root_pod)
          release_dir = Pathname.new(@root_dir+'.pod_release_temp_dir')
          raise "[rflow-release]::创建临时文件夹失败 'mkdir #{release_dir}'" unless File.exist?(release_dir) || system("mkdir #{release_dir}")
          system("rm -rf '#{release_dir}'")
          @git_info_need_release_pods.each do |dependency|
            if dependency.root_name == root_pod
              puts "merge #{root_pod}"
              git = dependency.external_source[:git]
              curr_branch = dependency.external_source[:branch] || 'master'

              cmd = %Q{
              set -e
              git clone #{git} '#{release_dir}/#{root_pod}'
              cd #{release_dir}/#{root_pod}
              git checkout -b '#{@target_branch}'
              git merge 'origin/#{curr_branch}'
              str=`git diff`;
              echo $str
              if [ -z "$str" ]; then
                  echo "没有任何变更$str"
                  git push origin '#{@target_branch}':'#{@target_branch}'
              else
                  git commit -am 'feat(pod-rflow):合并分支#{curr_branch}到#{@target_branch}'
                  git push origin '#{@target_branch}':'#{@target_branch}'
              fi
              echo "🚗🚗🚗🚗🚗🚗🚗🚗合并#{curr_branch}分支到#{@target_branch}成功"
              }
              raise "#{root_pod}::合并失败" unless system(cmd)
              system("rm -rf '#{release_dir}'")
            end
          end
          system("cd '#{@root_dir}'")
        end


        def podfile_modify(root_name)
          puts "🚀[pod-gflow] modify podfile #{root_name}".green
          dependencies = @podfile.need_release_pods.select {|item| item.root_name == root_name}
          text = File.read(@podfile.file_path)
          # puts dependencies
          dependencies.each do |pod|
            text.each_line { |line|
              if line.include?("'#{pod.name}'") || line.include?("\"#{pod.name}\"") || line.include?("'#{pod.root_name}'") || line.include?("\"#{pod.root_name}\"")
                # new_line = line.gsub(%r{,\s*:git\s*=>\s*['|"][\w|\S]+['|"]},'')
                new_line = line.gsub(%r{,\s*:branch\s*=>\s*['|"][\w|\S]+['|"]},", :branch => '#{@target_branch}'")
                puts new_line.yellow
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
            # curr_branch = Rocket::Utility::Git.curr_local_branch_name
            cmd = %Q{
            set -e
            git add Podfile*
            git commit -m 'feat(rocket-rflow): update podfile & podfile.lock'
            git push
            }
            system(cmd)
          end
        end

      end
    end
  end
end
