#Thanks to https://github.com/joenoon/url_safe_base64 for this technique
module Base64UrlSafe
  extend self
  
  def encode64(str)
    Base64.encode64(str).gsub(/[\s=]+/, "").gsub("+", "-").gsub("/", "_")
  end
  
  def decode64(str)
    case str.length.modulo(4)
    when 2
      str += '=='
    when 3
      str += '='
    end
    Base64.decode64(str.gsub("-", "+").gsub("_", "/"))
  end
end