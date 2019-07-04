require 'cocoapods-core'

class Pod::Command::Rocket
  module Utility
    class Podfile

      @podfile
      @podfile_path

      def initialize(path)
        @podfile = Pod::Podfile.from_file(path) if path
        puts @podfile.to_hash
        raise "can't find podfile at: #{path}" unless @podfile
        @podfile_path = path
      end


      def need_merge_pods(branch = nil )
        pod_arr = un_release_pods
        pod_arr.delete_if do |item|
          if branch.nil? || branch == 'master'
            item.external_source[:branch].nil? || item.external_source[:rkt_ignore] || (item.external_source[:branch] == branch)
          else
            item.external_source[:rkt_ignore] || (item.external_source[:branch] == branch)
          end
        end
        pod_arr
      end

      # @return 需要发布的分支
      def need_release_pods
        pod_arr = un_release_pods
        pod_arr.delete_if do |item|
          item.external_source[:rkt_ignore]
        end
        pod_arr
      end

      def un_release_pods()
        pod_arr = []
        @podfile.target_definitions.each do |target_definitions|

          target_definitions[1].dependencies.each do |dep|
            unless  dep.external_source.nil?
              pod_arr.append(dep)
            end
          end
        end
        pod_arr
      end


      def self.root_pods(pods)
        return unless pods.nil? || pods.empty?
        pods.map do |pod|
          pod.split('/').first.strip
        end
        pods.uniq
      end

      def file_path
        @podfile_path
      end

      def configurations_for_pod(pod)
        configurations = []
        @podfile.target_definitions.each do |target_definitions|

          puts target_definitions[1].raw_configuration_pod_whitelist
        end
        configurations
      end

    end
  end
end
