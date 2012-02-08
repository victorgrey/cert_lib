require 'openssl'
require 'base64'
require 'pathname'
require 'yajl/json_gem'

class Pathname
  # borrowed from extlib
  def /(path)
    (self + path).expand_path
  end
end
dir = Pathname(__FILE__).dirname.expand_path / 'cert-lib'

require dir / 'base64_urlsafe'
require dir / 'cert_serial'
require dir / 'pkey'
require dir / 'cert'
require dir / 'jwt'
