#!/usr/bin/env ruby
prefix = Regexp.escape(ARGV[0] || "/tmp/ruby")
new_paths = $LOAD_PATH.map do |path|
  path.sub(/^#{prefix}/, '$ROOT')
end
puts new_paths.join(":")
