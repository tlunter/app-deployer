# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'app_deployer/version'

Gem::Specification.new do |spec|
  spec.name          = 'app_deployer'
  spec.version       = AppDeployer::VERSION
  spec.authors       = ['Todd Lunter']
  spec.email         = ['tlunter@gmail.com']
  spec.description   = %q{Deploys to docker daemons and nginx load balancers}
  spec.summary       = %q{Deploys to docker daemons and nginx load balancers}
  spec.homepage      = 'https://github.com/tlunter/app_deployer'
  spec.license       = 'MIT'
  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'excon', '~> 0.45'
  spec.add_dependency 'nokogiri', '~> 1.6.4'
  spec.add_dependency 'docker-api', '~> 1.22'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'thor', '~> 0.19.1'
  spec.add_dependency 'net-ssh', '~> 2.9.2'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rspec', '~> 3.0.0'
  spec.add_development_dependency 'rubocop', '~> 0.25.0'
  spec.add_development_dependency 'simplecov', '~> 0.8.2'
  spec.add_development_dependency 'vcr', '~> 2.9.2'
end
