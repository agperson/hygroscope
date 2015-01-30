Gem::Specification.new do |s|
  s.name        = 'hygroscope'
  s.version     = '0.0.1'
  s.summary     = 'CloudFormation launcher'
  s.description = 'A tool for managing the launch of complex CloudFormation stacks'
  s.authors     = ['Daniel Silverman']
  s.email       = 'dsilverman@brightcove.com'
  s.homepage    = ''
  s.license     = 'MIT'

  s.files       = `git ls-files -z`.split("\x0")
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }

  s.add_dependency 'thor'
  s.add_dependency 'cfoo'
  s.add_dependency 'aws-sdk', '>= 2.0.0.pre'
  s.add_dependency 'archive-zip'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
end
