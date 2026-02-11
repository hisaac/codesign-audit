# frozen_string_literal: true

require_relative 'lib/csa/version'

Gem::Specification.new do |spec|
  github_repo = 'https://github.com/hisaac/codesign-audit'
  csa_path = "#{github_repo}/tree/main/csa"

  spec.name = 'csa'
  spec.version = CSA::VERSION
  spec.summary = 'CLI for querying App Store Connect signing certificates and profiles'
  spec.description = 'Command-line tool for querying Apple App Store Connect and Enterprise APIs for code-signing certificates and provisioning profiles.'
  spec.authors = ['Isaac Halvorson']
  spec.license = 'MIT'
  spec.homepage = csa_path
  spec.metadata = {
    'homepage_uri' => csa_path,
    'source_code_uri' => csa_path,
    'changelog_uri' => "#{csa_path}#readme",
    'rubygems_mfa_required' => 'true'
  }

  spec.required_ruby_version = '>= 3.1'

  spec.files = Dir[
    'bin/*',
    'lib/**/*.rb',
    'README.md',
    'LICENSE*'
  ]
  spec.bindir = 'bin'
  spec.executables = ['csa']
  spec.require_paths = ['lib']

  spec.add_dependency 'fastlane', '~> 2'
end
