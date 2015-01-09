Gem::Specification.new do |s|
  s.name        = 'hygroscope'
  s.version     = '1.0.0'
  s.summary     = 'CloudFormation launcher'
  s.description = 'Launch cfoo CloudFormation templates'
  s.authors     = ['Daniel Silverman']
  s.email       = 'dsilverman@brightcove.com'
  s.homepage    = ''
  s.license     = 'MIT'

  s.files       = `git ls-files -z`.split("\x0")
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }

  s.add_dependency 'thor'
  s.add_dependency 'aws-cli', '>= 2.0.0.pre'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'geminabox'
end
