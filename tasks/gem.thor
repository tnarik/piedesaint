class Gem < Thor  
    include Thor::Actions

    # This allows for dynamic descriptions
    begin
        @gemhelper = Bundler::GemHelper.new
    rescue
    end

    def initialize(*args)
        super
        @gemhelper = Bundler::GemHelper.new
    end

    # tasks
    desc "build", @gemhelper.nil? ? "Building gem into the pkg directory" : 
                        "Building #{@gemhelper.gemspec.name}-#{@gemhelper.gemspec.version}.gem into the pkg directory"
    def build
        @gemhelper.build_gem
    end

    desc "install", @gemhelper.nil? ? "Build and install gem into system gems" : 
                        "Build and install #{@gemhelper.gemspec.name}-#{@gemhelper.gemspec.version}.gem into system gems"
    def install
        @gemhelper.install_gem
    end

    desc "release", @gemhelper.nil? ? "Create tag and build and push gem to Rubygems" :
                        "Create tag v#{@gemhelper.gemspec.version} and build and push #{@gemhelper.gemspec.name}-#{@gemhelper.gemspec.version}.gem to Rubygems"
    def release
        @gemhelper.release_gem
    end
end  