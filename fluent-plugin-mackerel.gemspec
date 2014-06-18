# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-mackerel"
  spec.version       = "0.0.2"
  spec.authors       = ["tksmd"]
  spec.email         = ["someda@isenshi.com"]
  spec.description   = %q{fluent plugin to send metrics to mackerel.io}
  spec.summary       = spec.description
  spec.homepage      = "https://github.com/tksmd/fluent-plugin-mackerel"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "mackerel-client"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rr", ">= 1.0.0"
  spec.add_runtime_dependency "fluentd"

  spec.required_ruby_version = '>= 1.9.3'
end
