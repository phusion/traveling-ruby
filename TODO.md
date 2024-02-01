# TODO

Just some WIP notes to keep some track of testing progress

### Latest Ruby Versions
 
- `3.3.0`
- `3.2.3`
- `3.1.4`
- `3.1.2`
- `3.0.6`
- `3.0.4`
- `2.6.10`

#### Ruby Build Caveats

- Windows 3.3.0 builds not provdided
  - https://github.com/oneclick/rubyinstaller2/releases
- Linux
  - Cannot build latest `3.1.4` / `3.0.6`
- MacOS
  - Cannot build latest `3.1.4` / `3.0.6` on x86_64
  - Cannot build latest `2.7.8` on arm64
  - Cannot build `2.6.10` on either
  - `-dead_strip` linker command unused when running configure

### Ruby Versions failing to build

- Ruby `3.3.0`
  - Windows
    - Not Available

- Ruby  `3.1.3` / `3.1.4`
  - Linux 
    - OpenSSL not found error
  - MacOS (`x86_64`)

- Ruby  `3.0.5` / `3.0.6`
  - Linux
    - OpenSSL not found error


- Ruby  `2.7.8` / `3.0.6`
  - Linux
    - OpenSSL not found error

### Gems failing to install

- mysql2 `gem 'mysql2', :platforms => :ruby`
  - MacOS
  - Linux

### Gems failing testing

- `test-unit`
  - MacOS
  - Linux

- `win32ole`
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