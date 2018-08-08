require 'rake'
require_relative 'version.rb'

Gem::Specification.new do |s|
  s.name         = 'ovpn-key'
  s.version      = ::Version
  s.summary      = 'Key management utility for OpenVPN'
  s.description  = ''
  s.homepage     = 'https://github.com/chillum/ovpn-key'
  s.license      = 'Apache-2.0'
  s.author       = 'Vasily Korytov'
  s.email        = 'vasily.korytov@icloud.com'
  s.files        = FileList[%w(NOTICE README.md version.rb lib/functions.rb defaults/* defaults/meta/*)]
  s.executables << 'ovpn-key'
  s.add_dependency 'rubyzip', '~> 1.2'
  s.required_ruby_version = '>= 2.0'
end