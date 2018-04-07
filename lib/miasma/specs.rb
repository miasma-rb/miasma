Dir.glob(File.join(File.dirname(__FILE__), "specs", "*.rb")).each do |s_file|
  s_file_name = File.basename(s_file).sub(".rb", "")
  require "miasma/specs/#{s_file_name}"
end

def miasma_spec_sleep(interval = 20)
  if ENV["MIASMA_TEST_LIVE_REQUESTS"]
    sleep(20)
  else
    sleep(0.1)
  end
end
