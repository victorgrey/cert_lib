module CertLib
  module Base64UrlSafe
    extend self
  
    def encode(str)
      Base64.urlsafe_encode64(str).gsub(/[\s=]+/, "")
    end
  
    def decode(str)
      case str.length.modulo(4)
      when 2
        str += '=='
      when 3
        str += '='
      end
      Base64.urlsafe_decode64(str)
    end
  end
end