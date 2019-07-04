require 'cocoapods-rocket/utility/podfile'
require 'cocoapods-rocket/utility/lockfile'
require 'cocoapods-rocket/utility/configuration'

RSpec.describe Rocket::Utility do

  it 'utility podfile ' do
    podfile = Rocket::Utility::Podfile.new('/Users/infiq/Documents/git-space/caicai/dailuoboios/Podfile')
    pods = podfile.need_merge_pods('de1velop')
    puts "=================="
    puts "root-name:::#{pods.map {|pod| pod.root_name}}"
    puts "=================="
    # pods.each do |pod|
    #   puts pod
    # end
  end

  it 'utility rocket' do

    # json = File.read('./spec/utility/pod-rocket.json')
    # configuration = Rocket::Utility::Configuration.read_from_json(json)
    # puts system("#{configuration.lint_cmd}")
    #
    # puts "===#{configuration.push_cmds}====="
    # configuration.push_cmds.each do |cmd|
    #   # puts cmd
    #   puts system("#{cmd}")
    # end
  end


  it 'utility rocket >> podfile' do
    lockfile = Rocket::Utility::Lockfile.read_from('/Users/infiq/Documents/git-space/caicai/dailuoboios/Podfile.lock')
    puts lockfile.all_dependencies_for_pod('CCSSOLogin')

    ###### LockingDependencyAnalyzer #######
    # dependency_graph = Pod::Installer::Analyzer::LockingDependencyAnalyzer.generate_version_locking_dependencies(lockfile,[])
    # dependency_graph.vertices.each do |vertice|
    #   if vertice[1].root
    #   puts "#{vertice[1].name} ======= #{vertice[1].recursive_predecessors.map { |item| item.name  }}"
    #     end
    # end

    # puts lockfile.dependencies_to_lock_pod_named('Canos')
    # lockfile.internal_data['PODS'].each do |item|
    #   puts item
    # end

    # podfile = Rocket::Utility::Podfile.new('/Users/infiq/Documents/git-space/caicai/dailuoboios/Podfile')
    # podfile_dependency = Pod::Installer::Analyzer::PodfileDependencyCache.from_podfile(podfile)
    # podfile_dependency

    # pods = podfile.need_merge_pods('de1velop')
    # pods.each do |pod_dependency|
    #   # puts pod_dependency.class
    #   # puts pod_dependency.requirement.class
    # end
  end


  # it 'analyzer' do
  #   podfile = Rocket::Utility::Podfile.new('/Users/infiq/Documents/git-space/caicai/dailuoboios/Podfile')
  #   alalyzer = Installer::Analyzer.new(config.sandbox, podfile)
  #   puts alalyzer.
  # end



end
