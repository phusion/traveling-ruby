# TODO

Just some WIP notes to keep some track of testing progress

### Latest Ruby Versions

- `3.3.0`
- `3.2.3`
- `3.1.4`
- `3.0.6`
- `2.6.10`

#### Ruby Build Caveats

- 3.0.x and below builds require openssl 1.1.1
  - Set `OPENSSL_1_1_LEGACY` to build OpenSSL 1.1.1 for macos.
- Linux 2.6.10 - Requires bundler version 2.4.x (latest 2.4.22 at time of writing)

### Ruby Versions failing to build

- Linux  `3.0.5` / `3.0.6`
  - OpenSSL not found error (when using OpenSSL 3.2 or OpenSSL 1.1.1)
 - Linux  `2.7.8`
  - OpenSSL gem fails to build 
- MacOS  `2.6.10` / `2.7.8`

### Gems failing testing

- `test-unit`
  - MacOS
  - Linux

- `debug`
  - Ruby `3.0.x`

## Native Extensions

Currently `sqlite` and `nokogiri` provide native extensions in the 2nd format, where our guides/installers consider the first

- output/3.2.3-arm64/lib/ruby/gems/3.2.0/extensions/aarch64-linux/3.2.0-static/bcrypt-3.1.18/bcrypt_ext.so
  
We delete the version numbers, other than the version of ruby we are packaging, but we dont package up the extension

- output/3.2.3-arm64/lib/ruby/gems/3.2.0/gems/sqlite3-1.6.3-aarch64-linux/lib/sqlite3/3.2/sqlite3_native.so
- output/3.2.3-arm64/lib/ruby/gems/3.2.0/gems/sqlite3-1.6.3-aarch64-linux/lib/sqlite3/3.1/sqlite3_native.so
- output/3.2.3-arm64/lib/ruby/gems/3.2.0/gems/sqlite3-1.6.3-aarch64-linux/lib/sqlite3/3.0/sqlite3_native.so
- output/3.2.3-arm64/lib/ruby/gems/3.2.0/gems/sqlite3-1.6.3-aarch64-linux/lib/sqlite3/2.7/sqlite3_native.so

should we create a full fat bundler, that has all the gem extensions pre-installed?

- Now created as `-full` packages (Linux/MacOS only)
