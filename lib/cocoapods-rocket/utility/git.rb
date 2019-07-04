class Pod::Command::Rocket
  module Utility
    class Git

      def self.clone(git_url, local = nil)
        if name.nil?
          system "git clone #{git_url}"
        else
          system "git clone #{git_url} #{local}"
        end
      end

      def self.checkout(branch_name)
        system("git checkout #{branch_name}")
      end

      def self.branch_exist?(branch_name)
        system("git branch -a | grep #{branch_name}")
      end

      def self.pull(branch_name)
        system("git pull origin #{branch_name}")
      end

      def self.commit_all(message)
        return true unless self.any_diff?
        raise "请输入提交信息" if message.nil?
        system("git commit -am '#{message}' ")
      end

      def self.add_and_push_tag(tag, message='pod-rocket(tag): add tag')
        system("git tag -a #{tag} -m '#{message}' ")
        system("git push origin #{tag}")
      end

      def self.merge(branch)
        system("git merge #{branch}")
      end

      def self.push_to_branch(branch)
        system("git push origin #{branch}")
      end


      def self.curr_local_branch_name
        temp_file = (Pathname.pwd + '.pod-rocket-git-temp').freeze
        system %Q{br=`git branch | grep "*"`; echo ${br/* /} >> #{temp_file};}
        branch_name = File.read(temp_file)
        system "rm #{temp_file}"
        branch_name
      end


      def self.any_diff?(file=nil)
        diff = "git diff #{file}"
        diff = 'git diff' if file.nil?
        cmd = %Q{
            set -e
            str=`#{diff}`;
            echo $str
            if [ -z "$str" ]; then
                exit 1;
            fi
        }
        system(cmd)
      end

      def self.remote_branch_exit?(branch)
        cmd = %Q{
            set -e
            str=`git branch -r | grep 'origin/#{branch}'`;
            if [ -z "$str" ]; then
                exit 1;
            fi
            exit 0;
        }
        system(cmd)
      end



    end
  end
end
