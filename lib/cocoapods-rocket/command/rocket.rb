module Pod
  class Command
    # This is an example of a cocoapods plugin adding a top-level subcommand
    # to the 'utility' command.
    #
    # You can also create subcommands of existing or new commands. Say you
    # wanted to add a subcommand to `list` to show newly deprecated pods,
    # (e.g. `utility list deprecated`), there are a few things that would need
    # to change.
    #
    # - move this file to `lib/utility/command/list/deprecated.rb` and update
    #   the class to exist in the the Pod::Command::List namespace
    # - change this class to extend from `List` instead of `Command`. This
    #   tells the plugin system that it is a subcommand of `list`.
    # - edit `lib/cocoapods_plugins.rb` to require this file
    #
    # @todo Create a PR to add your plugin to CocoaPods/cocoapods.org
    #       in the `plugins.json` file, once your plugin is released.
    #
    class Rocket < Command

      require 'cocoapods-rocket/command/rocket/init'
      require 'cocoapods-rocket/command/rocket/release'


      # require 'pod/command/rocket/lint'
      # require 'pod/command/plugins/release'

      self.abstract_command = true
      # self.default_subcommand = 'list'

      self.summary = 'Show available CocoaPods plugins'
      self.description = <<-DESC
        Release or lint the available CocoaPods Project

        Also allows you to quickly release Cocoapods
        project.
      DESC



    end
  end
end
