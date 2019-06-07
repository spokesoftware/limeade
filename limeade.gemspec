lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'limeade/version'

Gem::Specification.new do |spec|
  spec.name          = 'limeade'
  spec.version       = Limeade::VERSION
  spec.authors       = ['David Pellegrini']
  spec.email         = ['david.pellegrini@spokesoftware.com']

  spec.summary       = %q{A Ruby interface to the LimeSurvey API.}
  spec.description   = %q{LimeSurvey exposes a JSON-RPC API for querying and managing surveys. This gem abstracts away the RPC calls and provides a friendly interface for Ruby clients.}
  spec.homepage      = 'https://github.com/spokesoftware/limeade'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'

    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['documentation_uri'] = "https://www.rubydoc.info/gems/limeade/#{spec.version}"
    spec.metadata['bug_tracker_uri'] = 'https://github.com/spokesoftware/limeade/issues'
    spec.metadata['source_code_uri'] = 'https://github.com/spokesoftware/limeade'
    spec.metadata['changelog_uri'] = 'https://github.com/spokesoftware/limeade/releases'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'faraday', '>= 0.12.0'
  spec.add_runtime_dependency 'multi_json', '~> 1.13'

  spec.add_development_dependency 'bundler', '>= 1.17', '< 3.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.2'
end
