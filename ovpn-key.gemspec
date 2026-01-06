# frozen_string_literal: true

require 'rake'
require_relative 'lib/version'

Gem::Specification.new do |s|
  s.name         = 'ovpn-key'
  s.version      = VERSION
  s.summary      = 'Key management utility for OpenVPN'
  s.description  = 'Generates and revokes certificates, also packs them to ZIP files with OpenVPN configuration'
  s.homepage     = 'https://github.com/chillum/ovpn-key'
  s.license      = 'Apache-2.0'
  s.author       = 'Vasily Korytov'
  s.email        = 'v.korytov@outlook.com'
  s.metadata     = { 'rubygems_mfa_required' => 'true' }
  s.files        = FileList[%w[NOTICE README.md lib/version.rb lib/functions.rb defaults/* defaults/meta/*]]
  s.executables << 'ovpn-key'
  s.add_dependency 'rubyzip', '~> 2.0'
  s.required_ruby_version = '>= 2.4'
end
