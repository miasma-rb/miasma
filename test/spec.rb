require 'vcr'
require 'webmock/minitest'
require 'minitest/autorun'

require 'miasma'

spec_dir = File.join(File.dirname(__FILE__), 'specs')

Dir.glob(File.join(spec_dir, '**/**/*_spec.rb')).each do |path|
  require File.expand_path(path)
end

VCR.configure do |c|
  c.cassette_library_dir = File.join(spec_dir, 'cassettes')
  c.hook_into :webmock
end
