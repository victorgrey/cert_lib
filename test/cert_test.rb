require File.expand_path(File.dirname(__FILE__) + '/test_helper')

describe "CertLib::Cert" do
  it "can generate an X509 subject" do
    subject = CertLib::Cert.generate_subject( :common_name => "metaconnectors.com",
                                              :organization => "MetaConnectors",
                                              :organizational_unit => "Testing Department",
                                              :city => "Concord", 
                                              :state => "California",
                                              :country => "US",
                                              :email => "example@example.com"
                                            )
                                       
    subject.must_be_instance_of(OpenSSL::X509::Name)
    subject.to_s.must_match(/CN=metaconnectors\.com/)
    subject.to_s.must_match(/O=MetaConnectors/)
    subject.to_s.must_match(/OU=Testing\sDepartment/)
    subject.to_s.must_match(/ST=California/)
    subject.to_s.must_match(/C=US/)
    subject.to_s.must_match(/L=Concord/)
    subject.to_s.must_match(/emailAddress=example@example\.com/)
  end
  
  it "should raise an exception if #generate_subject is not given a common name" do
    lambda {CertLib::Cert.generate_subject(:org => "MetaConnectors")}.must_raise(ArgumentError)
  end
  
  it "should generate a valid basic self-signed X509 certificate and key" do
    newcert, newkey = CertLib::Cert.create(:common_name => "foobar", :ex_comment => "A Test Cert")
    
    newcert.must_be_instance_of(CertLib::Cert)
    newkey.must_be_instance_of(CertLib::Pkey)
    
    newcert.cert.must_be_instance_of(OpenSSL::X509::Certificate)
    newkey.key.must_be_instance_of(OpenSSL::PKey::RSA)
    
    newcert.check_private_key(newkey.key).must_equal true  # checks that key is private key for this cert
    newcert.verify_cert_signature(newcert.public_key).must_equal true # checks that (self-signed) cert signature is made with private version of this public key
    
    newcert.cert.extensions.to_s.must_match(/CA:FALSE/)
    newcert.cert.extensions.to_s.must_match(/nsComment\s=\sA\sTest\sCert/)
    newkey.key.to_text.must_match(/Private\-Key:\s\(1024\sbit\)/)
  end
  
  it "should generate a self-signed certificate authority cert, given :ca => true" do
    newcert, newkey = CertLib::Cert.create(:common_name => "foobar", :ca => true)
    key = newkey.key
    cert = newcert.cert
    cert.extensions.to_s.must_match(/CA:TRUE/)
    key.to_text.must_match(/Private\-Key:\s\(2048\sbit\)/)
  end
  
  it "should generate a ca-signed cert given a certificate authority cert and a ca key" do
    ca_cert, ca_key = CertLib::Cert.create(:common_name => "metacnx", :ca => true)
    newcert, newkey = CertLib::Cert.create(:common_name => "foobar", :ca_cert => ca_cert.cert, :ca_key => ca_key.key)
    newcert.verify_cert_signature(ca_cert.public_key).must_equal true
  end
  
  it "should verify a signature made by a corresponding private key" do
    cert, key = CertLib::Cert.create(:common_name => "foobar")
    text_to_sign = "Twas brillig and the slithy toves"
    signature = key.sign(text_to_sign)
    cert.verify_signature(signature, text_to_sign).must_equal true
  end
  
  it "should fail to verify an incorrect signature" do
    cert, key = CertLib::Cert.create(:common_name => "foobar")
    text_to_sign = "Twas brillig and the slithy toves"
    signature = key.sign(text_to_sign)
    signature[1], signature[2], signature[3] = signature[3], signature[2], signature[1] #swap three characters
    cert.verify_signature(signature, text_to_sign).must_equal false
  end
  
end


