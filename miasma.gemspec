$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'
require 'miasma/version'
Gem::Specification.new do |s|
  s.name = 'miasma'
  s.version = Miasma::VERSION.version
  s.summary = 'Smoggy API'
  s.author = 'Chris Roberts'
  s.email = 'code@chrisroberts.org'
  s.homepage = 'https://github.com/miasma-rb/miasma'
  s.description = 'Smoggy API'
  s.license = 'Apache 2.0'
  s.require_path = 'lib'
  s.add_runtime_dependency 'http', '>= 0.8.12', '< 2.0'
  s.add_runtime_dependency 'multi_json'
  s.add_runtime_dependency 'multi_xml'
  s.add_runtime_dependency 'xml-simple'
  s.add_runtime_dependency 'bogo', '>= 0.2.2', '< 1.0'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest'
  s.files = Dir['{bin,lib}/**/*'] + %w(miasma.gemspec README.md CHANGELOG.md LICENSE)
end
