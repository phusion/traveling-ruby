## Next version

 * We now support multiple versions of native extension gems. For example, we now supply Nokogiri 1.5 and 1.6.

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

 * Initial release
