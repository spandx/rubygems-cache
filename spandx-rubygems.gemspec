require_relative 'lib/spandx/rubygems/version'

Gem::Specification.new do |spec|
  spec.name          = "spandx-rubygems"
  spec.version       = Spandx::Rubygems::VERSION
  spec.authors       = ["mo khan"]
  spec.email         = ["mo@mokhan.ca"]

  spec.summary       = %q{A index of software licenses for gems hosted on rubygems.org.}
  spec.description   = %q{A index of software licenses for gems hosted on rubygems.org.}
  spec.homepage      = "https://github.com/mokhan/spandx-rubygems"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mokhan/spandx-rubygems"
  spec.metadata["changelog_uri"] = "https://github.com/mokhan/spandx-rubygems/blob/master/CHANGELOG.md"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'msgpack', '~> 1.3'
  spec.add_dependency 'spandx', '~> 0.4'
end
