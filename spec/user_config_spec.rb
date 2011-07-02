require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe UserConfig do
  before(:all) do
    @root = File.join(File.dirname(__FILE__), 'config')
    if File.exist?(@root)
      raise "Temporary configuration directory '#{@root}' exists."
    end
  end

  subject do
    UserConfig.new('test', :root => @root)
  end

  it "should return directory" do
    uconf = UserConfig.new('dir1', :root => @root)
    uconf.directory.should == File.expand_path(File.join(@root, 'dir1'))
  end

  it "should create directory" do
    uconf = UserConfig.new('dir2', :root => @root)
    File.exist?(File.join(@root, 'dir2')).should be_true
  end

  it "should return file path under the directory" do
    uconf = UserConfig.new('dir3', :root => @root)
    uconf.file_path('path.yaml').should == File.join(@root, 'dir3', 'path.yaml')
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

  after(:all) do
    FileUtils.rm_r(@root)
  end
end
