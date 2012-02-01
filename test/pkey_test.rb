require File.expand_path(File.dirname(__FILE__) + '/test_helper')

describe "CertLib::Pkey" do
  before do
    @pk = CertLib::Pkey.create
  end
  
  it "should create a private/public key pair" do
    @pk.must_be_instance_of(CertLib::Pkey)
    @pk.key.must_be_instance_of(OpenSSL::PKey::RSA)
    @pk.public_key.must_be_instance_of(OpenSSL::PKey::RSA)
  end
  
  it "should read in a private/public key pair from input string" do
    pk2 = CertLib::Pkey.new(@pk.to_s)
    pk2.must_be_instance_of(CertLib::Pkey)
    pk2.key.must_be_instance_of(OpenSSL::PKey::RSA)
    pk2.public_key.must_be_instance_of(OpenSSL::PKey::RSA)
  end
  
  it "should read in a private/public key pair from input key object" do
    pk3 = CertLib::Pkey.new(@pk.key)
    pk3.must_be_instance_of(CertLib::Pkey)
    pk3.key.must_be_instance_of(OpenSSL::PKey::RSA)
    pk3.public_key.must_be_instance_of(OpenSSL::PKey::RSA)
  end
  
  it "should raise an exception if not provided a correct argument" do
    lambda {CertLib::Pkey.new(nil)}.must_raise(ArgumentError)
  end
  
  it "should decrypt text encrypted with the corresponding public key" do
    cert, key = CertLib::Cert.create(:common_name => "foobar")
    text_to_encrypt = "My rise to fame went unnoticed."
    encrypted = cert.encrypt(text_to_encrypt)
    key.decrypt(encrypted).must_equal text_to_encrypt
  end
  
  it "should fail quietly if encrypted text does not decrypt properly" do
    cert, key = CertLib::Cert.create(:common_name => "foobar")
    text_to_encrypt = "Fill in your own punch line."
    encrypted = cert.encrypt(text_to_encrypt)
    encrypted[1], encrypted[2], encrypted[3] = encrypted[3], encrypted[2], encrypted[1] # swap three characters
    key.decrypt(encrypted).must_be_nil
  end
end