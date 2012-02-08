require File.expand_path(File.dirname(__FILE__) + '/test_helper')

describe "JWT" do
  before do
    @cert, @key = CertLib::Cert.create( :common_name => "example.org", :organization =>  "Example")
    @payload = {"test" => "one", "and" => "two"}
  end
  
  it "should create a JSON Web Token" do
    jwt = CertLib::JWT.write(@payload, @key.key)
    jwt.must_match(/\A[\w\-]+\.[\w\-]+\.[\w\-]+\z/)
  end
  
  it "should extract the payload from a JSON Web Token" do
    jwt = CertLib::JWT.write(@payload, @key.key)
    decoded = CertLib::JWT.read(jwt, @cert.to_s)
    decoded.must_be_instance_of(Hash)
    decoded["test"].must_equal("one")
    decoded["and"].must_equal("two")
  end
  
  it "should raise an error for invalid JSON Web Tokens" do
    jwt = CertLib::JWT.write(@payload, @key.key)
    lambda {CertLib::JWT.read(jwt + '.', @cert.to_s)}.must_raise(CertLib::JWT::JWTError)
    lambda {CertLib::JWT.read(jwt.sub(/^[\w\-]+/, CertLib::Base64UrlSafe.encode({"typ" => "JWT", "alg" => "HS256"}.to_json)), @cert.to_s)}.must_raise(CertLib::JWT::JWTError)
    lambda {CertLib::JWT.read(jwt.sub(/(\.[\w\-]+\.)/, '.Zm9vYmFy.'), @cert.to_s)}.must_raise(CertLib::JWT::JWTError)
    lambda {CertLib::JWT.read(jwt.sub(/(\.[\w\-]+$)/, '.Zm9vYmFy'), @cert.to_s)}.must_raise(CertLib::JWT::JWTError)
  end
end