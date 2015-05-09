require 'piedesaint'

require 'openssl'
require 'yaml'
require 'json'

module Piedesaint

  # The CLI class encapsulates the behavior of Piedesaint when it is invoked
  # as a command-line utility. This allows other programs to embed Piedesaint
  # and preserve its command-line semantics.
  class CLI
    def initialize
    end

    def execute
      load_config
      cert(@config[:host]) if @config[:refresh_cert]
      refresh_asset_provider if @config[:refresh_asset_provider]
      piedesanto = Piedesaint.new @config
      piedesanto.start
    end

    def init ( parameters = [] )
      if File.exist?(".piedesaint")
        abort "Configuration already exists at #{Dir.pwd}/.piedesaint"
      end

      config = { iface: "0.0.0.0",
                  http_port: 8080,
                  https_port: 9292,
                  refresh_cert: true,
                  host: "localhost",
                  key: File.join(".", ".piedesaint", "ssl", "server.key" ),
                  cert: File.join(".", ".piedesaint", "ssl", "server.crt" ),
                  username: "user",
                  password: "password",
                  asset_provider_config: "",
                  asset_provider_helper_vagrantfile: "",
                  refresh_asset_provider: true,
                  freshness: 3600,
                  metastore: 'file:/tmp/rack/meta',
                  entitystore: 'file:/tmp/rack/body',
                  tar: true,
                  folders: parameters }
      save_config config
      cert
      puts "Configuration created at #{Dir.pwd}/.piedesaint"
    end

    def set_host ( host = [] )
      load_config
      @config[:host] = host[0]
      save_config @config
      cert host[0]
    end

    def asset_provider ( parameters = [] )
      load_config
      asset_provider_helper_vagrantfile = parameters[0] || "chef_vagrant"
      asset_provider_config = parameters[1] || File.join("kitchen", "nodes", "vagrant.json")
      @config[:asset_provider_helper_vagrantfile] = asset_provider_helper_vagrantfile
      @config[:asset_provider_config] = asset_provider_config
      save_config @config
    end

    private
    def load_config
      config_path = find_default_config_path
      if config_path.nil?
        abort "Configuration not provided.\nExecute '#{$PROGRAM_NAME} init' to generate one"
      end

      @config = YAML.load_file File.join(config_path, "config")
    end

    def save_config ( config )
      FileUtils.mkdir_p ".piedesaint"
      FileUtils.cd ".piedesaint" do
        open 'config', 'w' do |io| io.write config.to_yaml end
      end
    end

    def cert ( cn = 'localhost' )
      key, cert = create_ssl_artifacts cn

      FileUtils.mkdir_p ".piedesaint"
      FileUtils.cd ".piedesaint" do
        FileUtils.mkdir_p "ssl"
        FileUtils.cd "ssl" do
          open 'server.key', 'w' do |io| io.write key.to_pem end
          open 'server.crt', 'w' do |io| io.write cert.to_pem end
        end
      end
    end

    def refresh_asset_provider
      return if @config[:asset_provider_helper_vagrantfile].nil?
      return if @config[:asset_provider_helper_vagrantfile].empty?
      File.write(@config[:asset_provider_helper_vagrantfile], "trusted_certs_dir \"/vagrant/#{File.dirname(@config[:key])}\"")

      return if @config[:asset_provider_config].nil?
      return if @config[:asset_provider_config].empty?

      asset_provider_config = JSON.parse(File.read(@config[:asset_provider_config]))
      asset_provider_config["asset_provider"]["host"] = @config[:host]
      File.write(@config[:asset_provider_config], JSON.pretty_generate(asset_provider_config))
    end

    def create_ssl_artifacts ( cn = 'localhost' )
      key = OpenSSL::PKey::RSA.new 2048

      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 0
      cert.not_before = Time.now
      cert.not_after = Time.now + 3 * 3600
      cert.public_key = key.public_key
      name = OpenSSL::X509::Name.parse "CN=#{cn}"
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