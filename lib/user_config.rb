require 'fileutils'
require 'yaml'
require 'pathname'
require 'user_config/version'

class UserConfig
  class DirectoryExistenceError < StandardError
  end

  # Get default value of current class.
  # The value is a hash, of which keys are paths of yaml files.
  def self.default_value
    unless @default_value
      @default_value = {}
    end
    @default_value
  end

  # Set default values of the specified file of current class.
  # @param [String] path Relative path of the specified yaml file
  # @param [Hash] default_hash Default values
  def self.default(path, default_hash)
    self.default_value[path] = default_hash
  end

  attr_reader :directory

  # @param [String] directory_name :name of a configuration directory.
  # @option opts [String] :home Root directory, of which default value is ENV['HOME'].
  # @option opts [Integer] :permission A file permission of the configuration directory,
  #   of which default value is 0700.
  # @option opts [boolean] :new_directory
  #   If opts[:new_directory] is true and the directory exists then an error raises.
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

  # @param [String] path Relative path of a specified file
  # @param [boolean] create_directory If the value is true then we create parent directories recursively.
  # @return [String] An absolute path of a specified file
  def file_path(path, create_directory = nil)
    if Pathname(path).absolute?
      raise ArgumentError, "Path '#{path}' is absolute."
    end
    fpath = File.join(@directory, path)
    if create_directory && !File.exist?((dir = File.dirname(fpath)))
      FileUtils.mkdir_p(dir)
    end
    fpath
  end

  def default_value(path)
    self.class.default_value[path] || {}
  end
  private :default_value

  def load_file(path, merge = nil, value = nil)
    @file[path] = YAMLFile.new(file_path(path), value || default_value(path), :merge => merge)
  end
  private :load_file

  # Save the configuration file under the directory.
  # @param [String] path Relative path of target file
  # @param [Hash] value Values to be saved to the file
  def create(path, value = nil)
    yaml_file = load_file(path, true, value)
    yaml_file.save
  end

  # Make directory under the configuration directory.
  # @param [String] path Relative path of a directory
  # @param [Hash] opts Options
  # @option opts [Integer] :mode Permission for a directory to be created
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

  # Load the configuration file.
  # @param [String] path Relative path of a file to be loaded
  # @return [hash]
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

  # List files in the specified directory.
  # @param [String] dir A directory in which you want to list files.
  # @param [Hash] opts Options
  # @option opts [boolean] :absolute If the value is true then we get an array of absolute paths.
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

  # Open a file.
  # @param [String] path A path of the file
  # @param [String] mode A mode
  def open(path, mode, &block)
    full_path = file_path(path, true)
    f = Kernel.open(full_path, mode)
    if block_given?
      begin
        yield(f)
      ensure
        f.close
      end
      full_path
    else
      f
    end
  end

  # Read a file
  # @param [String] path A relative path of a file
  # @return [String] Strings of the file
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

    # @param [String] path A path of yaml file, which saves pairs of key and value.
    # @param [Hash] default A hash saving default value.
    # @param [Hash] opts Options
    # @option opts [booean] If the value is true then values of an instance are merged with default values.
    def initialize(path, default, opts = {})
      @path = path
      @default = default
      @cache = load_yaml_file
      if opts[:merge]
        @cache.merge!(@default)
      end
    end

    def load_yaml_file
      if File.exist?(path)
        YAML.load_file(path)
      else
        {}
      end
    end
    private :load_yaml_file

    def to_yaml
      YAML.dump(@cache)
    end

    # @param [boolean] merge If the value is true then we merges default values and cached values.
    # @return [Hash] A hash created by merging default values and cached values.
    def to_hash(merge = false)
      if merge
        @default.merge(@cache)
      else
        @cache
      end
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

    def delete(key)
      @cache.delete(key)
    end

    def set?(key)
      @cache.has_key?(key)
    end

    def method_missing(method_name, *args, &block)
      if Hash.method_defined?(method_name)
        to_hash(true).__send__(method_name, *args, &block)
      else
        super
      end
    end
  end
end
