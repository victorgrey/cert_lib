# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "version"

Gem::Specification.new do |s|
  s.name        = "cert_lib"
  s.version     = CertLib::VERSION
  s.authors     = ["Victor Grey"]
  s.email       = ["victor@metacnx.com"]
  s.homepage    = ""
  s.summary     = %q{A wrapper around openssl to make creating and using X509 certs easier.}
  s.description = %q{A wrapper around openssl to make creating and using X509 certs easier. Includes methods for instantiating certs and keys from their string representations, and using them for signing and verifying signatures and encrypting/decrypting.}

  #s.rubyforge_project = "cert_lib"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
