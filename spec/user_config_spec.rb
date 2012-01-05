require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class UserConfigCustom < UserConfig
end

describe UserConfig do
  before(:all) do
    @home = File.join(File.dirname(__FILE__), 'config')
    if File.exist?(@home)
      raise "Temporary configuration directory '#{@home}' exists."
    end
  end

  subject do
    UserConfig.new('test', :home => @home)
  end

  it "should return directory" do
    uconf = UserConfig.new('dir1', :home => @home)
    uconf.directory.should == File.expand_path(File.join(@home, 'dir1'))
  end

  it "should raise error" do
    UserConfig.new('dir1', :home => @home)
    lambda do
      uconf = UserConfig.new('dir1', :home => @home, :new_directory => true)
    end.should raise_error UserConfig::DirectoryExistenceError
  end

  it "should create directory" do
    uconf = UserConfig.new('dir2', :home => @home)
    File.exist?(File.join(@home, 'dir2')).should be_true
  end

  it "should return file path under the directory" do
    uconf = UserConfig.new('dir3', :home => @home)
    uconf.file_path('path.yaml').should == File.join(@home, 'dir3', 'path.yaml')
  end

  it "should create parent directory" do
    uconf = UserConfig.new('dir4', :home => @home)
    uconf.file_path('path/to/file.yaml', true)
    File.exist?(uconf.file_path('path/to')).should be_true
  end

  it "should create without parent directory" do
    uconf = UserConfig.new('dir5', :home => @home)
    uconf.file_path('path/to/file.yaml')
    File.exist?(uconf.file_path('path/to')).should be_false
  end

  it "should raise error" do
    lambda do
      subject.file_path('/abc/def.yaml')
    end.should raise_error ArgumentError
  end

  it "should set default value" do
    UserConfig.default('file1.yaml', 'abc' => 'ABC', 'def' => 'DEF')
    subject['file1.yaml']['abc'].should == 'ABC'
    subject['file1.yaml']['def'].should == 'DEF'
  end

  it "should return an array of files" do
    subject.load('tmp/file1.yaml')
    files = subject.all_file_paths
    files.should be_an_instance_of Array
    files.should include(File.join(subject.directory, 'tmp/file1.yaml'))
  end

  it "should save all files of yaml" do
    subject.load('save/file1.yaml')
    subject.save_all
    File.exist?(File.join(subject.directory, 'save/file1.yaml')).should be_true
  end

  it "should create a configuration file of default value" do
    yaml_path = 'create/test1.yaml'
    UserConfig.default(yaml_path, 'hello' => 'world')
    subject.create(yaml_path)
    path = File.join(subject.directory, yaml_path)
    File.exist?(path).should be_true
    data = File.read(path).split("\n")
    data.should have(2).items
    data[0].should match(/^---/)
    data[1].should match(/^hello/)
  end

  it "should create a configuration file from specified value" do
    yaml_path = 'create/test2.yaml'
    subject.create(yaml_path, 'first' => 123, 'second' => 456)
    path = File.join(subject.directory, yaml_path)
    File.exist?(path).should be_true
    data = File.read(path).split("\n")
    data.should have(3).items
    data[0].should match(/^---/)
    data[1].should match(/^first/)
    data[2].should match(/^second/)
  end

  it "should make directory" do
    subject.make_directory('tmp/directory')
    File.directory?(File.join(subject.directory, 'tmp/directory')).should be_true
  end

  it "should modify yaml file" do
    yaml_path = 'modify/test.yaml'
    full_path = subject.file_path(yaml_path)
    subject.create(yaml_path, 'first' => 123, 'second' => 456)
    File.read(full_path).should_not match(/^third/)
    yaml = subject[yaml_path]
    yaml['third'] = '789'
    subject.save_all
    File.read(full_path).should match(/^third/)
  end

  it "should check set." do
    yaml_path = 'set/test.yaml'
    yaml = subject[yaml_path]
    lambda do
      yaml['key'] = 'value'
    end.should change { yaml.set?('key') }
  end

  it "should delete value of key." do
    yaml_path = 'delete/test.yaml'
    yaml = subject[yaml_path]
    yaml['to_be_deleted'] = 123
    lambda do
      yaml.delete('to_be_deleted')
    end.should change { yaml.set?('to_be_deleted') }
  end

  it "should return false" do
    subject.exist?('not_exist/file.yaml').should_not be_true
  end

  it "should return path" do
    path = 'exist/file.yaml'
    subject.create(path)
    subject.exist?(path).should == File.join(subject.directory, path)
  end

  it "should delete a file" do
    path = 'delete/file.yaml'
    subject.create(path)
    subject.delete(path)
    subject.exist?(path).should_not be_true
  end

  it "should return nil" do
    subject.list_in_directory('not_exist2/').should be_nil
  end

  it "should return list of files" do
    files = ['list/file1.yaml', 'list/file2.yaml']
    files.each do |path|
      subject.create(path)
    end
    subject.list_in_directory('list').should == files.map do |path|
      path.sub(/^list\//, '')
    end
  end

  it "should return list of files of absolute path" do
    files = ['list2/file1.yaml', 'list2/file2.yaml']
    files.each do |path|
      subject.create(path)
    end
    subject.list_in_directory('list2', :absolute => true).should == files.map do |path|
      File.join(subject.directory, path)
    end
  end

  it "should save a raw file" do
    path ='save/raw/hello.txt'
    full_path = subject.open(path, 'w') do |f|
      f.puts 'hello world'
    end
    fpath = File.join(subject.directory, path)
    full_path.should == fpath
    File.exist?(fpath).should be_true
    File.read(fpath).strip.should == 'hello world'
  end

  it "should read a file" do
    path ='save/raw/hello.txt'
    full_path = subject.open(path, 'w') do |f|
      f.puts 'hello world'
    end
    fpath = File.join(subject.directory, path)
    full_path.should == fpath
    subject.read(path).should == File.read(fpath)
  end

  it "should return nil" do
    subject.read('not_exist/file.yaml').should be_nil
  end

  it "should have different default value" do
    UserConfigCustom.default_value.should be_an_instance_of Hash
    UserConfig.default_value.object_id.should_not == UserConfigCustom.default_value.object_id
  end

  context "when calling methods of Hash" do
    before(:all) do
      UserConfig.default("to_test_hash", { :a => "A", :b => "B" })
    end

    it "should be empty." do
      subject["empty_conf"].empty?.should be_true
    end

    it "should return merged hash" do
      subject["to_test_hash"][:b] = "BBB"
      subject["to_test_hash"].to_hash(true).should == { :a => "A", :b => "BBB" }
    end
  end

  after(:all) do
    FileUtils.rm_r(@home)
  end
end
