module CertLib
  class Pkey
    attr_reader :key
    def initialize(input_key)
      if input_key.instance_of?(OpenSSL::PKey::RSA)
        @key = input_key
      elsif input_key.instance_of?(String)
        @key = OpenSSL::PKey::RSA.new(input_key)
      else
        raise ArgumentError, "You must provide an OpenSSL::PKey::RSA or a string representation of it"
      end
    end
    
    def inspect
      puts @key.to_text
    end
    
    def to_s
      @key.to_pem
    end
    
    def public_key
      @key.public_key
    end
    
    # signs text with this key, base64 encoded by default
    def sign(text_to_sign, base64_encode=true)
      return nil if text_to_sign.nil? || text_to_sign.empty?
      sig = @key.sign(OpenSSL::Digest::SHA1.new, text_to_sign)
      base64_encode ? Base64.urlsafe_encode64(sig) : sig
    end
    
    # decrypts text with this key, assumes text is base64 encoded, unless 2rd arg is false
    def decrypt(text_to_decrypt, base64_encoded=true)
      text = base64_encoded ? Base64.urlsafe_decode64(text_to_decrypt) : text_to_decrypt
      begin
        @key.private_decrypt(text)
      rescue OpenSSL::PKey::RSAError
        nil
      end
    end
    
    def self.create(keytype=nil)
      keysize = (keytype == "ca") ? 2048 : 1024
      new(OpenSSL::PKey::RSA.new(keysize).to_pem)
    end
  end
end