module Pod
  module Downloader
    class Request

      alias pre_validate! validate!

      def validate!
        self.class.custom_params.each do |key|
          @params.delete(key)
        end
        pre_validate!
      end

      def self.custom_params
        [:rkt_ignore, :rkt_to_version].freeze
      end

    end
  end
end
