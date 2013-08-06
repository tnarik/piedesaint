require "piedesaint/version"

require 'puma/server'
require 'puma/events'
#require 'puma/minissl' #For Puma 2.0.1
require 'openssl'

require 'rack/ssl-enforcer'
require 'rack/cache'

require 'rubygems/package'
require "stringio"
require 'time'


module Piedesaint

  module Rack
    class DirectoryCompress < ::Rack::Directory
      def list_directory
        tarball = ::Piedesaint.tar(@path)
        etag = Digest::MD5.base64digest tarball.string
        headers = {"Cache-Control" => "public", "ETag" => etag }

        return [304, headers, []] if etag == @env['HTTP_IF_NONE_MATCH']
        return [200, headers, tarball]
      end
    end

    class FileEtag < ::Rack::File
      def serving(env)
        etag = Digest::MD5.file(@path).base64digest
        @headers['Cache-Control'] = "public"
        @headers['ETag'] = etag
        super
      end
    end

    class DirectoriesTraversal
      def initialize(options, app=nil)
        @apps = []
        @options = options.dup
        @options[:folders].each do |root|
          root = File.expand_path root
          puts "Service root: #{root}"
          @apps << ( @options[:tar] ? Rack::DirectoryCompress.new(root, app ? app : Rack::FileEtag.new(root)) : ::Rack::Directory.new(root) )
        end
      end

      def call(env)
        response = nil
        @apps.each do |app| 
          response = app.call(env)
          break unless response[0] == 404
        end
        response
      end
    end

  end

  class Piedesaint
    def initialize ( options = {} )
      @config = options
      @config[:folders] = [ "." ] if @config[:folders].empty?
    end

    def start
      ::Piedesaint.execute @config
    end
  end

  def self.app ( options = {} )
    ::Rack::Builder.app do 
      use ::Rack::CommonLogger
      use ::Rack::ShowExceptions
      use ::Rack::SslEnforcer, http_port: options[:http_port], https_port: options[:https_port]
      use ::Rack::Deflater
      if options[:username].nil? or options[:username].empty?
        puts "Service without Basic Authentication"
      else
        use ::Rack::Auth::Basic, "Icecreamland" do |username, password|
          ( options[:username] == username ) && ( options[:password] == password )
        end
      end
      use ::Rack::Deflater
      use ::Rack::Cache, verbose: true,
          metastore: 'file:/tmp/rack/meta',
          entitystore: 'file:/tmp/rack/body',
          default_ttl: options[:freshness]
      map "/" do
        run Rack::DirectoriesTraversal.new(options)
      end
      puts "Serving tar'ed folders" if options[:tar]
      puts "Service started at #{options[:http_port]} -> #{options[:https_port]}"
    end
  end

  def self.execute ( options = {} )
    event = ::Puma::Events.new STDOUT, STDERR
    puma = ::Puma::Server.new self.app( options ), event

    ## For Puma 2.0.1 (there is a bug regarding SSL and at least Ruby 1.9.3)
    ## Puma server doesn't receive 'event' (that's left to Puma::Binder)
    #binder = ::Puma::Binder.new event
    #puma.binder = binder
    #ctx = ::Puma::MiniSSL::SSLContext.new
    #ctx.key = "./server.key"
    #ctx.cert = "./server.crt"
    #ctx.verify_mode = ::Puma::MiniSSL::VERIFY_NONE

    ctx = ::OpenSSL::SSL::SSLContext.new
    ctx.key = OpenSSL::PKey::RSA.new File.read(options[:key])
    ctx.cert = OpenSSL::X509::Certificate.new File.read(options[:cert])
    ctx.verify_mode = ::OpenSSL::SSL::VERIFY_NONE

    puma.add_tcp_listener options[:host], options[:http_port]
    puma.add_ssl_listener options[:host], options[:https_port], ctx

    puma.min_threads = 1
    puma.max_threads = 10

    begin
      Signal.trap "SIGUSR2" do
        @restart = true
        puma.begin_restart
      end
    rescue Exception
      p "*** Sorry signal SIGUSR2 not implemented, restart feature disabled!"
    end

    begin
      Signal.trap "SIGTERM" do
        p " - Gracefully stopping, waiting for requests to finish"
        puma.stop false
      end
    rescue Exception
      p "*** Sorry signal SIGTERM not implemented, gracefully stopping feature disabled!"
    end
    
    begin
      puma.run.join
    rescue Interrupt
      graceful_stop puma
    end

    if @restart
      p "* Restarting..."
      @status.stop true if @status
      restart!
    end
  end


  def self.graceful_stop(puma)
    p " - Gracefully stopping, waiting for requests to finish"
    @status.stop(true) if @status
    puma.stop(true)
    p " - Goodbye!"
  end

  def self.tar(path)
    tar = StringIO.new
    Gem::Package::TarWriter.new(tar) do |tarwriter|
      Dir[File.join(path, "**/{*,.*}")].each do |file|
        mode = File.stat(file).mode
        relative_file = File.join(File.basename(path), file.sub(/^#{Regexp::escape path}\/?/, ''))

        if File.directory? file
          next if [ ".", ".."].include? File.basename(file)
          tarwriter.mkdir relative_file, mode
        else
          tarwriter.add_file(relative_file, mode)  do |filepart|
            File.open(file, "rb") { |f| filepart.write f.read }
          end
        end
      end
    end
    tar.rewind
    tar
  end

end
