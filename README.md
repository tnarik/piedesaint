# Piedesaint

## In short

[Piedesaint](https://github.com/tnarik/piedesaint) is a minimal web server designed to expose directly files and directories (in [TAR](http://en.wikipedia.org/wiki/Tar_(computing) format) via HTTP or HTTPS.

## Motivation

It was born from the need of having the simplest web server possible (while still being reasonably fast and secure) to provide files and directories to be used by [remote_file](http://docs.opscode.com/resource_remote_file.html) Chef resources, solving the issue of distributing packages that for different reasons are not public or require some interaction to get downloaded, without requiring the installation of a full fledged web server.

It also serves directories (packaging them on the fly) as a single resource.

## Installation

You can add this line to your application's Gemfile:

	gem 'piedesaint'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install piedesaint

## Usage

After installation you will need to initialize the configuration by executing:
	
	$ sug init [list of folders to serve, in cascade order]

This creates the ```.piedesaint``` folder that you can inspect and configure (it contains a default shortlived SSL key/certificate pair and some additional configuration in [YAML](http://en.wikipedia.org/wiki/YAML) format).

By default the configuration will serve the current directory, unless a list of folders is specified. If you want to serve a different folder or set of folders, just edit the configuration.

After this, whenever you want to serve the files/directories, just execute:

	$ sug

## License

MIT

## Contributing

If you want to contribute:

1. Just fork this project.
2. Create your feature branch (`git checkout -b my-new-feature`).
3. Commit your changes (`git commit -am 'Add some feature'`).
4. Push to the branch (`git push origin my-new-feature`).
5. Create new Pull Request.
