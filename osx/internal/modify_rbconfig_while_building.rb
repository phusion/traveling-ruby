require 'rbconfig'

[RbConfig::CONFIG, RbConfig::MAKEFILE_CONFIG].each do |config|
  ldflags = config["LDFLAGS"].dup
  ldflags = ldflags.split(/ +/)

  ldflags.reject! { |x| x =~ /^-L/ }
  ldflags << "-L."
  ldflags << "-L#{ENV['RUNTIME_DIR']}"
  ldflags << "-L/tmp/ruby/lib"
  ldflags << "-L/usr/lib"

  config["LDFLAGS"] = ldflags.join(" ")
end
