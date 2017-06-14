# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "sensu-redis"
  spec.version       = "2.2.0"
  spec.authors       = ["Sean Porter"]
  spec.email         = ["portertech@gmail.com"]
  spec.summary       = "The Sensu Redis client library"
  spec.description   = "The Sensu Redis client library"
  spec.homepage      = "https://github.com/sensu/sensu-redis"
  spec.license       = "MIT"

  spec.files         = Dir.glob("lib/**/*") + %w[sensu-redis.gemspec README.md LICENSE.txt]
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "eventmachine"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "10.5.0"
  spec.add_development_dependency "rspec"
end
