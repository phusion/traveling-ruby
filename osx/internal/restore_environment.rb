# encoding: utf-8
# immutable: string

IN_TRAVELING_RUBY = true

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
