lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/scm/tar/version'

Gem::Specification.new do |spec|
  spec.name          = 'capistrano-scm-tar'
  spec.version       = Capistrano::SCM::Tar::VERSION
  spec.authors       = %w[ziguzagu essjayhch]
  spec.email         = ['ziguzagu@gmail.com', 'essjayhch@gmail.com']
  spec.summary       = 'A tar strategy for Capistrano 3 to deploy tarball.'
  spec.description   = 'A tar strategy for Capistrano 3 to deploy tarball.'
  spec.homepage      = 'https://github.com/ziguzagu/capistrano-scm-tar'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'capistrano', '~> 3.0'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.0'
end
