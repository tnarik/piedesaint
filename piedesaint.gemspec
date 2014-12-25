# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'piedesaint/version'

Gem::Specification.new do |spec|
  spec.name          = "piedesaint"
  spec.version       = Piedesaint::VERSION
  spec.authors       = ["Tnarik Innael"]
  spec.email         = ["tnarik@gmail.com"]
  spec.description   = <<-EOF
Drop-in web server to serve files and tar'ed directories.
Use it as a tool to make available databse backups, installation packages that don't support automatic download, full GIT bare repositories, etc. for Chef Opscode cookbooks based on remote files.
Underlying it uses Puma, Basic Auth, SSL and SSL enforcing.
EOF
  spec.summary       = %q{Drop-in web server to serve files and tar'ed directories}
  spec.homepage      = "https://github.com/tnarik/piedesaint"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  # development dependencies
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"

  # runtime dependencies
  spec.add_dependency "puma", "~>1.6.3"
  spec.add_dependency "rack-ssl-enforcer"
  spec.add_dependency "rack-cache"

end
