require File.expand_path(File.dirname(__FILE__) + '/test_helper')

describe "Base64UrlSafe" do
  before do
    @bin = IO.read(File.dirname(__FILE__) + '/rails.png')
    @str = "This is a test string."
  end
  
  it "should encode the string" do
    encoded = Base64UrlSafe.encode64(@bin)
    encoded.must_match(/\A[\w\-]+\z/)
    encoded.length.must_equal 2383
    
    encoded_str = Base64UrlSafe.encode64(@str)
    encoded_str.must_equal "VGhpcyBpcyBhIHRlc3Qgc3RyaW5nLg"
  end
  
  it "should decode the encoded string" do
    encoded_str = Base64UrlSafe.encode64(@str)
    Base64UrlSafe.decode64(encoded_str).must_equal @str
  end
end