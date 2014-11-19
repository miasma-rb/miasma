$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'
require 'miasma/version'
Gem::Specification.new do |s|
  s.name = 'miasma'
  s.version = Miasma::VERSION.version
  s.summary = 'Smoggy API'
  s.author = 'Chris Roberts'
  s.email = 'code@chrisroberts.org'
  s.homepage = 'https://github.com/chrisroberts/miasma'
  s.description = 'Smoggy API'
  s.license = 'Apache 2.0'
  s.require_path = 'lib'
  s.add_dependency 'hashie'
  s.add_dependency 'http'
  s.add_dependency 'multi_json'
  s.add_dependency 'multi_xml'
  s.add_dependency 'xml-simple'
  s.files = Dir['lib/**/*'] + %w(miasma.gemspec README.md CHANGELOG.md LICENSE)
end
