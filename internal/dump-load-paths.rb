#!/usr/bin/env ruby
new_paths = $LOAD_PATH.map do |path|
  path.sub(%r{^/tmp/ruby}, '$ROOT')
end
puts new_paths.join(":")
