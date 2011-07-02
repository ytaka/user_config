require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe UserConfig::YAMLFile do
  before(:all) do
    current_dir = File.dirname(__FILE__)
    @test_yaml = File.join(current_dir, 'yaml', 'test_load.yaml')
    @tmp_dir = File.join(current_dir, 'tmp')
    if File.exist?(@tmp_dir)
      raise "Temporary directory '#{@tmp_dir}' exists."
    end
  end

  it "should return path" do
    UserConfig::YAMLFile.new(@test_yaml, {}).path.should == @test_yaml
  end

  it "should load yaml" do
    yaml = UserConfig::YAMLFile.new(@test_yaml, {})
    yaml['first'].should == 123
    yaml['second'].should == 456
  end

  it "should return nil" do
    yaml = UserConfig::YAMLFile.new(@test_yaml, {})
    yaml['third'].should be_nil
  end

  it "should return default value" do
    yaml = UserConfig::YAMLFile.new(@test_yaml, { 'third' => 789 })
    yaml['third'].should == 789
  end

  it "should return yaml" do
    yaml = UserConfig::YAMLFile.new(@test_yaml, { 'third' => 789 })
    yaml_line = yaml.to_yaml.split("\n")
    yaml_line.should have(3).items
    yaml_line[0].should match(/^---/)
    yaml_line[1].should match(/^first/)
    yaml_line[2].should match(/^second/)
  end
    
  it "should merge values" do
    yaml = UserConfig::YAMLFile.new(@test_yaml, { 'third' => 789 }, :merge => true)
    yaml.to_yaml.match(/^third/).should be_true
  end

  it "should set new value" do
    yaml = UserConfig::YAMLFile.new(@test_yaml, {})
    yaml['third'] = 12345
    yaml['third'].should == 12345
    yaml.to_yaml.match(/^third/).should be_true
  end

  it "should save yaml" do
    path = File.join(@tmp_dir, 'file1.yaml')
    yaml = UserConfig::YAMLFile.new(path, { 'abc' => 'ABC', 'def' => 'DEF' })
    yaml.save
    File.exist?(path).should be_true
  end

  it "should overwrite yaml" do
    path = File.join(@tmp_dir, 'file1.yaml')
    yaml = UserConfig::YAMLFile.new(path, {})
    yaml['hello'] = 'world'
    yaml.save
    yaml = UserConfig::YAMLFile.new(path, {})
    yaml['hello'].should == 'world'
    yaml['abc'].should be_nil
  end

  after(:all) do
    FileUtils.rm_r(@tmp_dir)
  end
end
