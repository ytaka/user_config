require 'fileutils'
require 'yaml'
require 'pathname'

class UserConfig
  class DirectoryExistenceError < StandardError
  end

  def self.default_value
    unless @default_value
      @default_value = {}
    end
    @default_value
  end

  def self.default(path, default_hash)
    self.default_value[path] = default_hash
  end

  attr_reader :directory

  # +directory_name+ is a name of a configuration directory.
  # opts[:home] is root directory, of which default value is ENV['HOME'].
  # opts[:permission] is a file permission of the configuration directory,
  # of which default value is 0700.
  # If opts[:new_directory] is true and the directory exists
  # then an error raises.
  def initialize(directory_name, opts = {})
    @directory = File.expand_path(File.join(opts[:home] || ENV['HOME'], directory_name))
    @file = {}
    if File.exist?(@directory)
      if opts[:new_directory]
        raise UserConfig::DirectoryExistenceError, "Can not create new directory: #{@directory}"
      end
    else
      FileUtils.mkdir_p(@directory)
      FileUtils.chmod(opts[:permission] || 0700, @directory)
    end
  end

  def file_path(path)
    if Pathname(path).absolute?
      raise ArgumentError, "Path '#{path}' is absolute."
    end
    File.join(@directory, path)
  end

  def default_value(path)
    self.class.default_value[path] || {}
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
    fpath
  end

  # Load the configuration file of +path+.
  def load(path)
    @file[path] || load_file(path)
  end

  alias_method :[], :load

  # Return an array of paths of all cached files.
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

  # Return full path if +path+ exists under the configuration directory.
  # Otherwise, false.
  def exist?(path)
    fpath = file_path(path)
    File.exist?(fpath) ? fpath : false
  end

  # Delete a file of +path+.
  def delete(path)
    if path.size > 0
      FileUtils.rm_r(file_path(path))
    else
      raise ArgumentError, "Path string is empty."
    end
  end

  # List files in directory +dir+.
  # If opts[:absolute] is true, return an array of absolute paths.
  def list_in_directory(dir, opts = {})
    fpath = file_path(dir)
    if File.directory?(fpath)
      files = Dir.entries(fpath).delete_if do |d|
        /^\.+$/ =~ d
      end.sort
      if opts[:absolute]
        files.map! do |path|
          File.join(fpath, path)
        end
      end
      files
    else
      nil
    end
  end

  # Open file of +path+ with +mode+.
  def open(path, mode, &block)
    fpath = file_path(path)
    unless File.exist?((dir = File.dirname(fpath)))
      FileUtils.mkdir_p(dir)
    end
    f = Kernel.open(fpath, mode)
    if block_given?
      begin
        yield(f)
      ensure
        f.close
      end
    else
      f
    end
  end

  # Read file of +path+ and return a string.
  def read(path)
    fpath = file_path(path)
    if File.exist?(fpath)
      File.read(fpath)
    else
      nil
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
      Kernel.open(path, 'w') do |f|
        YAML.dump(@cache, f)
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
