Gem::Specification.new do |spec|
  spec.name          = 'lita-pagerduty'
  spec.version       = '0.2.0'
  spec.authors       = ['Eric Sigler']
  spec.email         = ['eric@pagerduty.com']
  spec.description   = 'A Lita handler to interact with PagerDuty'
  spec.summary       = 'A Lita handler to interact with PagerDuty'
  spec.homepage      = 'http://github.com/esigler/lita-pagerduty'
  spec.license       = 'MIT'
  spec.metadata      = { 'lita_plugin_type' => 'handler' }

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin\/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)\/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'lita', '>= 4.0'
  spec.add_runtime_dependency 'pagerduty-sdk', '>= 1.0.9'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '>= 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
end
