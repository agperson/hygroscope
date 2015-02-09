Gem::Specification.new do |s|
  s.name        = 'hygroscope'
  s.version     = '1.1.3'
  s.summary     = 'CloudFormation launcher'
  s.description = 'A tool for managing the launch of complex CloudFormation stacks'
  s.authors     = ['Daniel Silverman']
  s.email       = 'me@agperson.com'
  s.homepage    = 'http://agperson.github.io/hygroscope/'
  s.license     = 'MIT'

  s.files       = `git ls-files -z`.split("\x0")
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }

  s.add_dependency 'thor'
  s.add_dependency 'cfoo', '>= 0.0.5'
  s.add_dependency 'aws-sdk', '>= 2.0.0.pre'
  s.add_dependency 'archive-zip'
  s.add_dependency 'json_color'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rubocop'
end
