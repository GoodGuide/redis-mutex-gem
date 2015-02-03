# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis_mutex/version'

Gem::Specification.new do |spec|
  spec.name          = "redis_mutex"
  if ENV['TRAVIS']
    spec.version       = "#{RedisMutex::VERSION}-alpha-#{ENV['TRAVIS_BUILD_NUMBER']}"
  else
    spec.version       = RedisMutex::VERSION
  end
  spec.authors       = ["Ryan Taylor Long"]
  spec.email         = ["ryan.long@goodguide.com"]
  spec.summary       = %q{Simple distributed mutex using Redis.}
  spec.description   = %q{}
  spec.homepage      = "https://github.com/GoodGuide/redis_mutex"
  spec.license       = "MIT"
  spec.required_ruby_version = '>= 1.9.3'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.5.0"
  spec.add_runtime_dependency 'redis', '~> 3.2.0'
end
