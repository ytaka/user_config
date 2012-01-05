# user_config

user_config is a library to manage configuration files in user's home directory
for ruby libraries or applications.
The format of a configuration file is yaml.

## Behavior

The class UserConfig manages values of configuration,
which is handled as a set of hashes and is saved to yaml files
in specified directory under user's home directory.

## Examples

### Simple usage

    uconf = UserConfig.new(".some_config")

The directory ~/.some\_config is created in the directory ENV['HOME'].
To set the value "world" for the key "hello" of ~/.some\_config/file.yaml,

    uconf["file.yaml"]["hello"] = "world"

The value is not saved to the file. To do that,

    uconf["file.yaml"].save

### Create initial configuration files

If we want to create initial files with default values,
we use the method UserConfig#default.

    UserConfig.default('conf.yaml', { 'key1' => 'val1', 'key2' => 'val2' })
    uconf = UserConfig.new('.some_config')
    uconf.create('conf.yaml')

The file ~/.some_config'/confi.yaml is created.
To create another file 'conf2.yaml',

    UserConfig.default('conf2.yaml', { 'hello' => 'world'})
    uconf.create('conf2.yaml')

### Load configuration file

We load files in the above example as the following code.

    uconf = UserConfig.new('.some_config')
    yaml = uconf['conf.yaml']
    p yaml['key1']
    p yaml['key2']

### Set new values and save to files

UserConfig#save_all save all yaml files.

    uconf = UserConfig.new('.some_config')
    yaml = uconf['conf.yaml']
    yaml['key1'] = 'modified_val1'
    yaml['key3'] = 'val3'
    yaml.save

If we modify some files, we can save all files by UserConfig#save_all.

    yaml2 = uconf['conf2.yaml']
    yaml2['new_key'] = 'ABCDE'
    uconf.save_all

### Behavior like a hash

In internal of UserConfig::YAMLFile, the methods of Hash is called except for some methods.

    uconf = UserConfig.new('.some_config')
    yaml = uconf['conf.yaml']
    yaml.each do |key, val|
      ...
    end
    yaml.empty?

## Contributing to user_config
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 Takayuki YAMAGUCHI. See LICENSE.txt for
further details.

