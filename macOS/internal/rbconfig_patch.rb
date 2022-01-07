# Traveling Ruby modifications:
# get rid of our custom compilation flags.
[RbConfig::CONFIG, RbConfig::MAKEFILE_CONFIG].each do |config|
  config["CC"] = (String.new << "xcrun clang")
  config["CXX"] = (String.new << "xcrun clang++")
  config["CPP"] = (String.new << "xcrun clang -E")
  config["LDSHARED"] = (String.new << "xcrun clang -dynamic -bundle")
  config["LDSHAREDXX"] = (String.new << "xcrun clang++ -dynamic -bundle")
  config["CFLAGS"] = config["cflags"].dup
  config["CXXFLAGS"] = config["cxxflags"].dup
  config["RUBY_EXEC_PREFIX"] = config["exec_prefix"].dup
  config.delete("CC_VERSION")
end
