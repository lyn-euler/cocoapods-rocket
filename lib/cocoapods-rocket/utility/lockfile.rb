class Pod::Command::Rocket
  module Utility
    class Lockfile

      def initialize(path)
        @pods_dependencies = read_dependencies_from_path(path)
        @root_pods_dependencies = read_root_dependencies_from_path(path)
      end

      def self.read_from(path)
        Lockfile.new(path)
      end

      public
      def find_pod_dependencies(pod, format_dependencies)
        return if pod.nil?
        select_hashs = format_dependencies.select{|hash| hash.keys.include?(pod)}
        dependencies = []
        unless select_hashs.nil? || select_hashs.empty?
          select_hash = select_hashs.first
          # puts select_hash
          dep_pods = select_hash[pod]
          unless dep_pods.nil? || dep_pods.empty?
            dependencies << dep_pods
          end
          dep_pods.each do |dep_pod|
            dependencies << find_pod_dependencies(dep_pod, format_dependencies - select_hashs)
          end
        end
        dependencies.flatten.uniq
      end

      def all_dependencies_for_pod(pod_name)
        find_pod_dependencies(pod_name, @pods_dependencies).map {|item| item.split('/').first.strip}.uniq.select {|item| item != pod_name.split('/').first.strip}
      end

      def all_root_dependencies_for_pod(root_pod)
        find_pod_dependencies(root_pod, @root_pods_dependencies)
      end


      private
      def read_dependencies_from_path(path)

        filepath = Pathname.new(path)
        lockfile = Pod::Lockfile.from_file(filepath)
        lock_pods = lockfile.internal_data['PODS'].select{|item| item.is_a?(Hash)}
        format_pods(lock_pods)
      end

      def read_root_dependencies_from_path(path)

        filepath = Pathname.new(path)
        lockfile = Pod::Lockfile.from_file(filepath)
        lock_pods = lockfile.internal_data['PODS'].select{|item| item.is_a?(Hash)}
        format_to_root_pods(lock_pods)
      end

      def format_pods(pods)
        pods.map do |hash|
          format_hash = Hash.new()
          hash.each_key { |key|
            format_hash[key.split('(').first.strip] =  hash[key].map{|item| item.split('(').first.strip}
          }
          format_hash
        end
      end

      def format_to_root_pods(pods)
        pods.map do |hash|
          format_hash = Hash.new()
          hash.each_key { |key|
            root_key = key.split('(').first.strip.split('/').first.strip
            if format_hash[root_key].nil?
              format_hash[root_key] =  hash[key].map{|item| item.split('(').first.strip}.map {|item| item.split('/').first.strip}.uniq.select{|item| item != root_key}
            else
              format_hash[root_key] <<  hash[key].map{|item| item.split('(').first.strip}.map {|item| item.split('/').first.strip}.uniq.select{|item| item != root_key}
            end
          }
          format_hash
        end
      end

    end
  end
end
