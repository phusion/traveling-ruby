# Traveling Ruby modifications:
# Get rid of our custom compilation flags.
[RbConfig::CONFIG, RbConfig::MAKEFILE_CONFIG].each do |config|
  config["CFLAGS"] = config["cflags"].dup
  config["CXXFLAGS"] = config["cxxflags"].dup
  config["RUBY_EXEC_PREFIX"] = config["exec_prefix"].dup
end
