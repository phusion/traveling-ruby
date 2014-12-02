# encoding: utf-8
# immutable: string

require 'rbconfig'

restorable_envs = ['DYLD_LIBRARY_PATH', 'TERMINFO', 'RUBYOPT', 'RUBYLIB'].freeze
restorable_envs.each do |name|
  ENV[name] = ENV["ORIG_#{name}"]
  ENV.delete("ORIG_#{name}")
end

# We can't restore these environments now because they'll be used later.
# We just store the original values so that the program can decide what to do.
$OVERRIDDEN_ENVIRONMENTS = {
  'SSL_CERT_DIR'  => ENV['OLD_SSL_CERT_DIR'],
  'SSL_CERT_FILE' => ENV['OLD_SSL_CERT_FILE']
}

# Get rid of our custom compilation flags.
RbConfig::CONFIG["CC"] = (String.new << "xcrun clang")
RbConfig::CONFIG["CXX"] = (String.new << "xcrun clang++")
RbConfig::CONFIG["CPP"] = (String.new << "xcrun clang -E")
RbConfig::CONFIG["LDSHARED"] = (String.new << "xcrun clang -dynamic -bundle")
RbConfig::CONFIG["LDSHAREDXX"] = (String.new << "xcrun clang++ -dynamic -bundle")
RbConfig::CONFIG["CFLAGS"] = RbConfig::CONFIG["cflags"].dup
RbConfig::CONFIG["CXXFLAGS"] = RbConfig::CONFIG["cxxflags"].dup
RbConfig::CONFIG["RUBY_EXEC_PREFIX"] = RbConfig::CONFIG["exec_prefix"].dup
RbConfig::CONFIG.delete("CC_VERSION")
