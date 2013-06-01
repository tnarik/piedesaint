require 'piedesaint'

require 'openssl'
require 'yaml'

module Piedesaint

  # The CLI class encapsulates the behavior of Piedesaint when it is invoked
  # as a command-line utility. This allows other programs to embed Piedesaint
  # and preserve its command-line semantics.
  class CLI
    def initialize
    end

    def execute
      load_config
      piedesanto = Piedesaint.new @config
      piedesanto.start
    end

    def init ( parameters )
      if File.exist?(".piedesaint")
        abort "Configuration already exists at #{Dir.pwd}/.piedesaint"
      end
      key, cert = create_ssl_artifacts

      FileUtils.mkdir_p ".piedesaint"
      FileUtils.cd ".piedesaint" do
        FileUtils.mkdir_p "ssl"
        FileUtils.cd "ssl" do
          open 'server.key', 'w' do |io| io.write key.to_pem end
          open 'server.crt', 'w' do |io| io.write cert.to_pem end
        end

        config = { host: "0.0.0.0",
                    http_port: 8080,
                    https_port: 9292,
                    key: File.join(".", ".piedesaint", "ssl", "server.key" ),
                    cert: File.join(".", ".piedesaint", "ssl", "server.crt" ),
                    username: "user",
                    password: "password",
                    folders: parameters }

        open 'config', 'w' do |io| io.write config.to_yaml end
      end

      puts "Configuration created at #{Dir.pwd}/.piedesaint"
    end

    private
    def load_config
      config_path = find_default_config_path
      if config_path.nil?
        abort "Configuration not provided.\nExecute '#{$PROGRAM_NAME} init' to generate one"
      end

      @config = YAML.load_file File.join(config_path, "config")
    end

    def create_ssl_artifacts
      key = OpenSSL::PKey::RSA.new 2048

      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 0
      cert.not_before = Time.now
      cert.not_after = Time.now + 3 * 3600
      cert.public_key = key.public_key
      name = OpenSSL::X509::Name.parse 'CN=Piedesaint'
      cert.subject = name
      cert.issuer = name
      cert.sign key, OpenSSL::Digest::SHA1.new

      return key, cert
    end

    def find_default_config_path
      previous = nil
      current  = File.expand_path(Dir.pwd)
      until !File.directory?(current) || current == previous
        filename = File.join(current, '.piedesaint')
        return filename if File.directory?(filename)
        current, previous = File.expand_path("..", current), current
      end
      nil
    end

  end
end