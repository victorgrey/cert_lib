module CertLib
  module CertSerial
    extend self
    
    class InvalidCertSerial < StandardError; end
    
    if defined?(CertLogRoot) # should be an instance of Pathname
      # CertLog#id should return a never-repeating integer.
      # The expectation is that in Rails we will use a DataMapper or ActiveRecord class named CertLog,
      # but this is provided as a backstop and to run the gem tests.
      class CertLog
        attr_reader :id
        def initialize(opts={})
          @id = 1
          @subject = opts[:subject] ? opts[:subject] : ""
          @expires_after = opts[:expires_after] ? opts[:expires_after] : ""
        end
        
        def save
          certlog_dir = CertLogRoot + 'certlog'
          certlog_dir.mkpath
          if File.exists?(certlog_dir + 'certlog.txt')
            filepath = (certlog_dir + 'certlog.txt').realpath.to_s
            @id = `tail -n1 #{filepath}`[/^\d+/].to_i + 1
            (certlog_dir + 'certlog.txt').open('a') do |file| 
              file.write("#{@id} #{@subject} #{@expires_after}\n")
            end
          else
            (certlog_dir + 'certlog.txt').open('w') do |file| 
              file.write("#{@id} #{@subject} #{@expires_after}\n")
            end
          end
        end
      end
    end
    
    def number(opts={})
      certlog = CertLog.new(opts)
      if certlog.save
        certlog.id
      else
        raise InvalidCertSerial
      end
    end
    
    # use a Mongoid model
    def mongo_number(opts={})
      certlog = CertLog.new(opts)
      if certlog.save
        certlog.id.to_s.to_i(16)
      else
        raise InvalidCertSerial
      end
    end
    
  end
end