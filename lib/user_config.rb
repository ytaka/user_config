require 'fileutils'
require 'yaml'

class UserConfig
  @@default_value = {}

  def self.default(path, default_hash)
    @@default_value[path] = default_hash
  end

  attr_reader :directory

  # +directory_name+ is a name of a configuration directory.
  # opts[:root] is root directory, of which default value is ENV['HOME'].
  # opts[:permission] is a file permission of the configuration directory,
  # of which default value is 0700.
  def initialize(directory_name, opts = {})
    @directory = File.expand_path(File.join(opts[:root] || ENV['HOME'], directory_name))
    @file = {}
    unless File.exist?(@directory)
      FileUtils.mkdir_p(@directory)
      FileUtils.chmod(opts[:permission] || 0700, @directory)
    end
  end

  def file_path(path)
    File.join(@directory, path)
  end

  def default_value(path)
    @@default_value[path] || {}
  end
  private :default_value

  def load_file(path, merge = nil, value = nil)
    @file[path] = YAMLFile.new(file_path(path), value || default_value(path), :merge => merge)
  end
  private :load_file

  # Save the configuration file of +path+.
  # If we set a hash to +value+ then its value is saved to the new configuration file.
  def create(path, value = nil)
    yaml_file = load_file(path, true, value)
    yaml_file.save
  end

  # Make directory under the configuration directory.
  def make_directory(path, opts = {})
    fpath = file_path(path)
    unless File.exist?(fpath)
      FileUtils.mkdir_p(fpath)
    end
    if opts[:mode]
      FileUtils.chmod(fpath, opts[:mode])
    end
  end

  # Load the configuration file of +path+.
  def load(path)
    @file[path] || load_file(path)
  end

  alias_method :[], :load

  # Return an array of paths of all files.
  def all_file_paths
    @file.map do |ary|
      file_path(ary[0])
    end
  end

  # Save all configuration files that have already loaded.
  def save_all
    @file.each_value do |yaml_file|
      yaml_file.save
    end
  end

  class YAMLFile
    attr_reader :path

    # +path+ is path of yaml file, which saves pairs of key and value.
    # +default+ is a hash saving default value.
    # if +opts[:merge]+ is true then values of an instance are merged with default values.
    def initialize(path, default, opts = {})
      @path = path
      @default = default
      @cache = load
      if opts[:merge]
        @cache.merge!(@default)
      end
    end

    def load
      if File.exist?(path)
        YAML.load_file(path)
      else
        {}
      end
    end
    private :load

    def to_yaml
      YAML.dump(@cache)
    end

    # Save cached values to the path of file.
    def save
      unless File.exist?((dir = File.dirname(path)))
        FileUtils.mkdir_p(dir)
      end
      open(path, 'w') do |f|
        f.print to_yaml
      end
    end

    def [](key)
      @cache[key] || @default[key]
    end

    def []=(key, val)
      @cache[key] = val
    end
  end
end
