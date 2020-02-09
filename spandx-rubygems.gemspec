# frozen_string_literal: true

require_relative 'lib/spandx/rubygems/version'

Gem::Specification.new do |spec|
  spec.name          = 'spandx-rubygems'
  spec.version       = Spandx::Rubygems::VERSION
  spec.authors       = ['mo khan']
  spec.email         = ['mo@mokhan.ca']

  spec.summary       = 'A index of software licenses for gems hosted on rubygems.org.'
  spec.description   = 'A index of software licenses for gems hosted on rubygems.org.'
  spec.homepage      = 'https://github.com/mokhan/spandx-rubygems'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.4.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/mokhan/spandx-rubygems'
  spec.metadata['changelog_uri'] = 'https://github.com/mokhan/spandx-rubygems/blob/master/CHANGELOG.md'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'bindata', '~> 2.4'
  spec.add_dependency 'msgpack', '~> 1.3'
  spec.add_dependency 'net-hippie', '~> 0.3'
  spec.add_dependency 'nokogiri', '~> 1.10'
  spec.add_dependency 'pg', '~> 1.2'
  spec.add_dependency 'thor'

  spec.add_development_dependency 'bundler-audit', '~> 0.6'
  spec.add_development_dependency 'rubocop', '~> 0.52'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.22'
  spec.add_development_dependency 'vcr', '~> 5.1'
  spec.add_development_dependency 'webmock', '~> 3.8'
end
