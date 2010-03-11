$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
CertLogRoot = Pathname.new(File.join(File.dirname(__FILE__), '..'))

require 'cert_lib'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
  
end

