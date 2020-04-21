# cocoapods-rocket cli工具

<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@glorious/demo/dist/gdemo.min.css">
<script src="https://cdn.jsdelivr.net/npm/@glorious/demo/dist/gdemo.min.js"></script>

<script>
const gdemo = new GDemo('[data-demo-container]');

const code = 'console.log("Hello World!");'

const highlightedCode = Prism.highlight(
  code,
  Prism.languages.javascript,
  'javascript'
);

gdemo
  .openApp('editor', { minHeight: '400px', windowTitle: 'demo.js' })
  .write(highlightedCode, { onCompleteDelay: 2000 })
  .openApp('terminal', { minHeight: '400px', promptString: '$' })
  .command('node ./demo')
  .respond('Hello World!')
  .command('')
  .end();
</script>
## 起源
**组件化** 已经是这年说烂的概念了, 大大小小的团队多少也在推行组件化, 至少也会对一些公用基础组件进行拆分封装提升互用性. 而业内更多的都是基于组件的颗粒度拆分、解耦隔离、组件通信等. 如同微服务架构更多的人关注的是微服务的“small“ 和 “lightweight“, 但实际中真正决定微服务架构成熟度的更多因素却是在“automated“. 和客户端组件化一样, 业务发展的过程中, 组件或服务的粒度拆分不合理, 团队实际落地遇到问题, 自然也会去想着拆服务or拆分组件. 而基础设施的健全与否才是整个组件化过程中的团队协作&研发效率的瓶颈. 
![f866d73aa62748074b6ddcfc1cee92](media/15620360952905/f866d73aa62748074b6ddcfc1cee92c1.png)


### 现有发布流程

```mermaid
graph LR
    start[开始] --> m01[查看主工程profile]
    m01 --> judge1{是否有需要发布的子库}
    judge1 -- 有 --> release_dep1[获取子库到本地]
    judge1 -- 无 --> release_main[pod update, 并发布主工程]
    subgraph 发布子库
    release_dep1 --> release_dep1_lint[执行lint]
    release_dep1_lint --> release_dep1_judge1{lint 是否成功}
    release_dep1_judge1 -- 成功 --> release_dep1_tag[打tag并推送remote]
    release_dep1_judge1 -- 失败 --> check_dep[检查原因,并修改]
    check_dep --> release_dep1_lint
    release_dep1_tag --> release_dep1_push[pod push repo]
    end
    
    release_dep1_push --> judge2{子库发布成功}
    
    judge2 -- 成功 --> modify_podfile[修改podfile]
    judge2 -- 失败 --> check_dep[检查原因]
    modify_podfile --> judge1
    
    release_main --> end[结束]
    
```


1. 查看 Podfile 中需要发布的子库
2. `clone` 子库进行 `pod lint`, 如果依赖库没有发布失败, 则先 clone 依赖库lint, 通过则进行第 3 步
3. 添加 tag 并合并到master & develop 分支
4. `pod repo push` 发布子库
5. 修改 Podfile 并 `pod update` 主工程提交 lock 文件

### 问题
1. gitflow 工作流分支切换频繁, 子库的分支切换及其耗费时间精力
2. 如果不进行子库分支切换, 并发协作容易出现冲突
3. 手动修改版本号和主工程文件, 麻烦也容易出错
4. 发布时依赖库没发布会导致发布失败, 需要人工排查依赖库

基于此 `cocopods-rocket` 孕育而生
## rocket Usage

- 初始化子库
```ruby
pod rocket init --template-url=http://xxxxx
```

- 单库发布
```ruby
pod rocket release
```

- 主工程批量切换分支
```ruby
pod rflow merge --target-branch=develop
```

- 主工程批量发布
``` ruby
pod rflow release
```

- Podfile 扩展
新增 `:rkt_ignore` 和 `:rkt_version` 参数
**:rkt_ignore** 是否忽略改pod的分支切换or发布操作
**:rkt_version** 指定pod发布的版本号
```ruby
platform :ios, '8.0'
inhibit_all_warnings!
#source 'https://github.com/CocoaPods/Specs.git'
target 'RocketSample' do
pod 'CocoaRocket', :git => 'https://xx.git.com/cocoa-rocket.git', :branch => 'develop', :rkt_ignore => true, :rkt_version = '2.1.0'
end
```

## rocket 实现
### 技术栈
目前我们组件库都是基于cocoapods在做, cocoapods 是一套gem工具, 所以在选型的时候自然而然就使用ruby了(当然内部实现有些需要用到shell脚本). 对团队的技术栈和cocoapods工具的功能扩展都方便.
### 单库发布
首先需要支持的自然也就是独立pod库的一键发布了. 这里其实没什么可说的, 跟 fastlane 实现的基本一致, 主要是涉及到版本号的修改和git的操作遵循 gitflow 的流程操作.

```ruby
raise "[pod-rocket]::ERROR lint end" unless pod_lint # 执行 pod lint
bump_version(@to_version) # 修改版本号, 默认自增1的hotfix版本
push_changes_and_tag # push 修改的文件和tag
pod_repo_push # 发布
```
对于lint 和 repo 的参数会有 init 配置决定(原本考虑直接扩展podspec, 但这样对原有体系会有侵入, 也不方便后期扩展).
### 主工程发布

#### Podfie分析
从上面流程图中可以看到, 要做主工程的批量发布, 首先要解决的是获取需要发布的依赖库. 这里采用的是直接生成 Pod 对象, 从该 ruby 对象中解析出直接指向路径的.
这里还涉及到一个问题, 对于有些库我可能是不需要发布的. 这时候就需要扩展原来 pod 的参数. 如果是直接加会在下载source的时候校验参数会报错. 所以 rockect hook了 Request 类.在 validate! 的时候移除自定义参数.

#### 依赖分析
由于 pods 库发布存在依赖关系, 对于一个需要发布的库如果依赖库没有发布成功就发布.会lint 失败. 所以需要先进行依赖分析. 
cocoapods 在install存在分析的类, 会把工程里的所有依赖解析成graph并在lock文件中有保存.
所以 rocket 直接通过lock文件解析出每个库的依赖. 主要是要注意依赖库 root_name 和 name 切换.
依赖的发布流程大致如下

| A B C D E | A B D E | A B | A |
| --- | --- | --- | --- |
| <div>— A</div><div>   — B</div><div>   — C</div><div>      — D</div><div>— B</div><div>   — C</div><div>     — D</div><div>— D</div><div>— E</div> |  <div>— A</div> <div>   — B</div><div>   -— C-</div><div>   — D</div><div>— B</div><div>   -— C-</div><div>   — D</div><div>— D</div><div>— E</div> | <div>— A</div><div>   — B</div><div>   -— D-</div><div>— B</div><div>   -— D-</div><div>-— D-</div><div>-— E-</div> |  <div>— A</div><div>   -— B-</div><div>   -— D-</div><div>-— B-</div><div>   -— D-</div><div>-— D-</div><div>-— E-</div> |

#### 自动修改&提交
子库的自动 push 和 git 分支操作, 这里遵循gitflow的工作流程, 调用上面的单库发布命令. 
Podfile 的修改, 本来打算通过 ruby 对象直接自己解析属性输出但考虑到 env case和原文件的变更情况采用了 sed 正则替换.后续考虑下是否迁移到ruby对象输出, 其实pod也支持yaml和hash的格式输出, 但这样会改变原有的工作模式.

```ruby
def to_hash
      hash = {}
      hash['target_definitions'] = root_target_definitions.map(&:to_hash)
      hash.merge!(internal_hash)
      hash
    end

    # @return [String] The YAML representation of the Podfile.
    #
    def to_yaml
      require 'cocoapods-core/yaml_helper'
      "---\n" << YAMLHelper.convert_hash(to_hash, HASH_KEYS)
    end
```
## TODO
- [ ] 完整的发布流程图
- [ ] Podfile 生成方式修改
- [ ] CI 集成
- [ ] 依赖分析优化
- [ ] 可视化发布系统
- [ ] 二进制切换管理