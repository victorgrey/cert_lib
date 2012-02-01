require File.expand_path(File.dirname(__FILE__) + '/test_helper')

describe "CertLib::CertSerial" do
  describe "with a valid model" do
    it "should generate an incrementing serial number" do
      num1 = CertLib::CertSerial.number(:subject => "/CN=foobar")
      num1.must_be_kind_of(Integer)
      num2 = CertLib::CertSerial.number(:subject => "/CN=foobaz")
      num2.must_be :>, num1
    end
  end
end