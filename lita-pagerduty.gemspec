Gem::Specification.new do |spec|
  spec.name          = "lita-pagerduty"
  spec.version       = "0.0.1"
  spec.authors       = ["Eric Sigler"]
  spec.email         = ["me@esigler.com"]
  spec.description   = %q{A Lita handler to interact with PagerDuty}
  spec.summary       = %q{A Lita handler to interact with PagerDuty}
  spec.homepage      = "http://github.com/esigler/lita-pagerduty"
  spec.license       = "MIT"
  spec.metadata      = { "lita_plugin_type" => "handler" }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 3.0"
  spec.add_runtime_dependency "pagerduty-sdk"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 3.0.0.beta2"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "coveralls"
end
