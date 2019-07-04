require 'cocoapods-rocket/utility/scanner'
require 'cocoapods-rocket/utility/configuration'
require 'net/http'
require 'json'
require 'colored2'

module Pod
  class Command
    class Rocket
      class Init < Rocket
        self.summary = 'init rocket project.'

        self.description = <<-DESC
          create .pod-rocket.json file for project
        DESC

        # self.arguments = 'NAME'
        #

        def self.options
          [
              ['--template-url=URL', 'the URL of the .pod-rocket.json template'],
              ['--use-default=USE_DEFAULT_CONFIG', 'use default config']
          ].concat(super)
        end

        def initialize(argv)
          # @name = ''
          @template_url = argv.option('template-url', DEFAULT_TEMPLATE_URL)
          @use_defalut_config = argv.option('use-default', false)
          super
        end

        def validate!
          super

        end

        def run
          response = Net::HTTP.get_response(URI.parse(@template_url))
          json = JSON.parse(response.body)

          raise "读取模版文件失败：#{@template_url}" if json.nil?

          _name = podspec_to_init.name
          json["name"] = _name
          json["name"] = Rocket::Utility::Scanner.ask("请输入名称（默认是）#{_name}:", _name) unless  @use_defalut_config

          # @configuration = Rocket::Utility::Configuration.new(json)
          rocket_file = File.new('.pod-rocket.json', "w+")
          rocket_file.puts(JSON.pretty_generate(json))
          rocket_file.close
        end

        private
        def podspec_to_init
          podspecs = Pathname.glob(Pathname.pwd + '*.podspec{.json,}')
          if podspecs.count.zero?
            raise Informative, 'Unable to find a podspec in the working ' \
                'directory' \
                "at: #{Pathname.pwd}"
          end
          podspecs.each do |path|
            return Specification.from_file(path)
          end
        end


        DEFAULT_TEMPLATE_URL = 'https://pod-rocket.oss-cn-hongkong.aliyuncs.com/pod-rocket.json'

      end
    end
  end
end
