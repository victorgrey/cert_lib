require 'pathname'
CertLogRoot = Pathname.new(File.join(File.dirname(__FILE__), '..'))
require 'cert_lib'
require 'minitest/spec'
require 'minitest/autorun'
