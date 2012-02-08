module CertLib
  module JWT
    extend self
    class JWTError < StandardError; end
    
    def write(payload, privkey)
      header_and_payload = [encoded_header, encoded_payload(payload)].join('.')
      [header_and_payload, encoded_signature(header_and_payload, privkey)].join('.')
    end
  
    def read(jwt, x509cert)
      hdr, payload, signature = validate_jwt(jwt)
      if validate_header(hdr) && verify_signature([hdr, payload].join('.'), signature, x509cert)
        decode_and_validate_payload(payload)
      else
        raise JWTError, "Cannot validate signature."
      end
    end
    
    private
    def encoded_header
      Base64UrlSafe.encode({"typ" => "JWT", "alg" => "RS256"}.to_json)
    end
    
    def encoded_payload(payload)
      if payload.instance_of?(String)
        begin
          JSON.parse(payload)  # test for valid JSON
          Base64UrlSafe.encode(payload)
        rescue JSON::ParserError => e
          raise JWTError, "Payload is invalid JSON: #{e}"
        end
      else
        raise JWTError, "Payload must be a Hash or valid JSON." unless payload.kind_of?(Hash)
        Base64UrlSafe.encode(payload.to_json)
      end
    end
    
    def encoded_signature(to_be_signed, privkey)
      k = Pkey.new(privkey)
      k.sign_and_encode(to_be_signed)
    end
    
    def validate_jwt(jwt)
      if jwt =~ /\A[\w\-]+\.[\w\-]+\.[\w\-]+\z/
        jwt.split('.')
      else
        raise JWTError, "Invalid JWT format."
      end
    end
    
    def validate_header(hdr)
      begin
        header = JSON.parse(Base64UrlSafe.decode(hdr))
      rescue Exception => e
        raise JWTError, e.message
      end
      raise JWTError, "Invalid or unimplemented JWT header: #{header.to_json}" unless header["typ"] == "JWT" && header["alg"] == "RS256"
      !!header
    end
    
    def verify_signature(signed, sig, x509cert)
      c = CertLib::Cert.new(x509cert)
      c.verify_signature(sig, signed)
    end
    
    def decode_and_validate_payload(payload)
      begin
        JSON.parse(Base64UrlSafe.decode(payload))
      rescue Exception => e
        raise JWTError, "Invalid payload: #{e}"
      end
    end
  end
end