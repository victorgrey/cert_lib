require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "CertLib::CertSerial" do
  
  describe "with a valid model" do
    it "should generate an incrementing serial number" do
      num1 = CertLib::CertSerial.number(:subject => "/CN=foobar")
      num1.should be_kind_of(Integer)
      num2 = CertLib::CertSerial.number(:subject => "/CN=foobaz")
      num2.should > num1
    end
  end
  
  describe "with a invalid model" do
    before(:each) do
      module ::CertLib; module CertSerial; class CertLog; def save; false; end; end; end; end
    end
    
    it "should raise an InvalidSerial exception on failure" do
      lambda {CertLib::CertSerial.number(:subject => "/CN=foobar")}.should raise_exception(CertLib::CertSerial::InvalidCertSerial)
    end
  end
  
end