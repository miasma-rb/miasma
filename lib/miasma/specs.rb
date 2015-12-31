Dir.glob(File.join(File.dirname(__FILE__), 'specs', '*.rb')).each do |s_file|
  s_file_name = File.basename(s_file).sub('.rb', '')
  require "miasma/specs/#{s_file_name}"
end
