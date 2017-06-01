# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'git_watcher/version'

Gem::Specification.new do |spec|
  spec.name          = 'git_watcher'
  spec.version       = GitWatcher::VERSION
  spec.authors       = ['Mikail Demidov']
  spec.email         = ['mike.house.nsk@gmail.com']

  spec.summary       = %q{Tracks git repos last commits}
  spec.description   = %q{You can watch for many repositories and its branches at the same time}
  spec.homepage      = 'https://github.com/mikehouse'
  spec.license       = 'MIT'

  spec.files         = Dir[File.join('lib/**', '*.rb')]
  spec.executables   = ['git_watcher']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'json'
  spec.add_development_dependency 'whenever'
end
