## Version 20150130-next

 * Added additonal native extension versions:
   - bcrypt 3.1.10
   - eventmachine 1.0.6
   - json 1.8.2
   - mini_portile 0.6.2
   - nokogiri 1.6.6.2
   - sqlite3 1.3.10
   - nokogumbo 1.2.0
   - rugged 0.22.0b5

## Version 20150130

Upgrading to this version is strongly recommended because of the OpenSSL upgrade, which fixes some security vulnerabilities!

 * Added the following native extension gems: RedCloth, escape_utils, posix-spawn, nokogumbo, github-markdown, rugged, charlock_holmes, unf_ext.
 * Upgraded to OpenSSL 1.0.1l.
 * The Linux version and the OS X version now use the same CA root certificates. Closes GH-24.

## Version 20141224

 * Fixed the mysql2 native extension not working on Linux. This is done by dynamically linking against libstdc++. Closes GH-21.
 * Added the eventmachine and thin native extension gems.

## Version 20141219

 * Removed header files. This makes the package 100 KB smaller.
 * Removed the sdbm extension because almost nobody uses it. The sqlite3 gem is almost always a better choice anyway.
 * Added the yajl-ruby native extension gem.

## Version 20141215

 * The Linux packages now include libffi.so.6, which was forgotten in the previous release. Closes GH-16.

## Version 20141213

 * Further removed unnecessary files. The Ruby binary packages were about 10 MB before. They are now about 6 MB.
 * Supports native extensions.

## Version 20141209

 * Fixed inclusion of Bundler.

## Version 20141206

 * Initial release.
