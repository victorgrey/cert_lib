module CertLib
  class Cert
    attr_reader :cert
    def initialize(input_cert)
      if input_cert.instance_of?(OpenSSL::X509::Certificate)
        @cert = input_cert
      elsif input_cert.instance_of?(String)
        @cert = OpenSSL::X509::Certificate.new(input_cert)
      else
        raise ArgumentError, "You must provide an OpenSSL::X509::Certificate or a string representation of it"
      end
    end
    
    def inspect
      puts @cert.to_text
    end
    
    def public_key
      @cert.public_key
    end
    
    def to_s
      @cert.to_pem
    end
    
    # Verify that the private key corresponding to this cert created the signature over the signed text.
    # Assumes a base64 encoded signature, unless 3rd arg is false
    def verify_signature(signature, signed_text, base64_encoded=true)
      sig = base64_encoded ? Base64.urlsafe_decode64(signature) : signature
      self.public_key.verify(OpenSSL::Digest::SHA1.new, sig, signed_text)
    end
    
    # Encrypt text with this public key, so that only the corresponding private key can decrypt
    # Base64 encodes the result unless second arg is false
    def encrypt(text_to_encrypt, base64_encode=true)
      encrytped = public_key.public_encrypt(text_to_encrypt)
      base64_encode ? Base64.urlsafe_encode64(encrytped) : encrytped
    end
    
    def subject
      @cert.subject.to_s
    end
    
    def serial
      @cert.serial
    end
    
    def expires
      @cert.not_after.strftime("%Y-%m-%d %H:%M:%S")
    end
    
    def expires_xmlschema
      @cert.not_after.strftime("%Y-%m-%dT%H:%M:%SZ")
    end
    
    # to use as a json string, the newlines must be escaped
    def to_json_value
      @cert.to_pem.gsub(/\n/, "\\n")
    end
    
    def check_private_key(priv_key)
      @cert.check_private_key(priv_key)
    end
    
    def verify_cert_signature(pub_key)
      @cert.verify(pub_key)
    end
    
    # Create an X509 public key certificate (see http://en.wikipedia.org/wiki/X.509)
    # The argument hash may contain the following values:
    #
    # :common_name  => String, required, forms the minimum Subject of the cert, 
    #     i.e. the entity to which the cert refers
    #
    # :email, :organization, :organizational_unit, :city, :state, :country
    #     => String's, these optionally add to the Subject of the cert
    #
    # :not_before, :not_after  ## Time instances, representing the time period for which the cert is valid 
    #     - defaults to from yesterday to one year from now
    #
    # :ca  => Boolean, whether this should be a self-signed Certificate Authority certificate, default false
    #
    # :ca_cert  => OpenSSL::X509::Certificate, Certificate Authority's certificate, or nil for a self-signed certificate
    #
    # :ca_key  => OpenSSL::PKey::RSA, the Certificate Authority private key with which to sign the cert -
    #     if :ca is true and :ca_key is present, that indicates that we are renewing the ca_cert for this key
    #
    # :key  => OpenSSL::PKey::RSA, if present indicates that we are renewing the cert for this key,
    #     rather than creating a new one.
    #
    # :ex_comment  => Enter a comment field into the cert extensions if desired
    #
    #
    # The method returns an Array, the first element of which contains a CertLib::Cert instance,
    #     and if a new key has been generated the second element contains a CertLib::Pkey instance.
    # Store their #to_s outputs in a file or database field 
    #     -- the key should be kept very secure, the cert is meant to be public
    
    def self.create(opts={})
      cert = OpenSSL::X509::Certificate.new

      cert.subject = generate_subject(opts)
      cert.not_before = opts[:not_before].instance_of?(Time) ? opts[:not_before] : Time.now - (60*60*24) # one day in the past
      cert.not_after = opts[:not_after].instance_of?(Time) ? opts[:not_after] : Time.now + (365 * 24 * 60 * 60) # one year in the future
      if opts[:mongo_cert_log]
        cert.serial = CertLib::CertSerial.mongo_number(:subject => cert.subject.to_s, :expires_after => cert.not_after.strftime("%Y-%m-%d %H:%M:%S"))
      else
        cert.serial = CertLib::CertSerial.number(:subject => cert.subject.to_s, :expires_after => cert.not_after.strftime("%Y-%m-%d %H:%M:%S"))
      end
      cert.version = 2 # X509v3
      
      if opts[:key]
        cert_key = CertLib::Pkey.new(opts[:key])
        new_key = false
      else
        cert_key = CertLib::Pkey.create(opts[:ca] ? "ca" : nil)
        new_key = true
      end
      cert.public_key = cert_key.public_key
      issuer, issuer_cert, signing_key = issuer_data(cert, cert_key, opts)
      cert.issuer = issuer
      cert.extensions = extensions(cert, issuer_cert, opts)

      cert.sign(signing_key, OpenSSL::Digest::SHA1.new)
      
      output = [new(cert)]
      output << cert_key if new_key
      output
    end
    
    def self.opts_to_X509_names
      { :common_name         => "CN",
        :organization        => "O",
        :organizational_unit => "OU",
        :city                => "L",
        :state               => "ST",
        :country             => "C",
        :email               => "emailAddress" }
    end

    def self.generate_subject(opts={})
      ## as well as the required common name, any of the fields in #opts_to_X509_names may be specified
      if opts[:common_name].nil? || opts[:common_name].empty?
        raise ArgumentError, "Common name must be specified"
      end
      subject = opts_to_X509_names.map {|k,v| [v, opts[k]] if opts.include?(k)}.compact
      OpenSSL::X509::Name.new subject
    end
    
    def self.issuer_data(cert, cert_key, opts)
      if opts[:ca]
        issuer_cert = cert
        issuer = cert.subject
        signing_key = cert_key.key
      else
        if opts[:ca_cert]
          issuer_cert = opts[:ca_cert]
          issuer = opts[:ca_cert].subject
        else
          issuer_cert = cert
          issuer = cert.subject
        end
        if opts[:ca_key]
          signing_key = opts[:ca_key]
        else
          signing_key = cert_key.key
        end
      end
      [issuer, issuer_cert, signing_key]
    end
    
    def self.extensions(subject_cert, issuer_cert, opts)
      extension_factory = OpenSSL::X509::ExtensionFactory.new
      extension_factory.subject_certificate = subject_cert
      extension_factory.issuer_certificate = issuer_cert

      extensions = Array.new
      if opts[:ca]
        basic_constraint = "CA:TRUE"
        key_usage = %w{cRLSign keyCertSign digitalSignature keyEncipherment}
        extensions << extension_factory.create_extension("authorityKeyIdentifier", "keyid,issuer:always")
      else
        basic_constraint = "CA:FALSE"
        key_usage = %w{digitalSignature keyEncipherment}
      end
      ext_key_usage = %w{serverAuth clientAuth emailProtection}
      extensions << extension_factory.create_extension("nsComment", %Q{#{opts[:ex_comment]}}) if opts[:ex_comment]
      extensions << extension_factory.create_extension("basicConstraints", basic_constraint, true)
      extensions << extension_factory.create_extension("subjectKeyIdentifier", "hash")
      extensions << extension_factory.create_extension("keyUsage", key_usage.join(","))
      extensions << extension_factory.create_extension("extendedKeyUsage", ext_key_usage.join(","))
      
      extensions
    end
    
  end
  
end