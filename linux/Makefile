VERSION := $(shell cat ../VERSION.txt)
RUBY_VERSION := $(shell cat ../RUBY_VERSION.txt)

PACKAGE := traveling-ruby-$(VERSION)-$(RUBY_VERSION)-linux
CONCURRENCY := 2

.PHONY: package upload

package: $(PACKAGE)-x86.tar.gz $(PACKAGE)-x86_64.tar.gz

$(PACKAGE)-x86.tar.gz: runtime/x86 output/x86
	cd output/x86 && env GZIP=--best tar -czf ../../$(PACKAGE)-x86.tar.gz *

$(PACKAGE)-x86_64.tar.gz: runtime/x86_64 output/x86_64
	cd output/x86 && env GZIP=--best tar -czf ../../$(PACKAGE)-x86_64.tar.gz *

runtime/x86:
	rm -rf runtime/x86.tmp
	mkdir -p runtime/x86.tmp
	./setup-runtime -a x86 runtime/x86.tmp
	rm -rf runtime/x86
	mv runtime/x86.tmp runtime/x86

runtime/x86_64:
	rm -rf runtime/x86_64.tmp
	mkdir -p runtime/x86_64.tmp
	./setup-runtime -a x86_64 runtime/x86_64.tmp
	rm -rf runtime/x86_64
	mv runtime/x86_64.tmp runtime/x86_64

output/x86:
	rm -rf output/x86.tmp
	mkdir -p output/x86.tmp
	./build -j $(CONCURRENCY) -a x86 runtime/x86 output/x86.tmp
	rm -rf runtime/x86
	mv output/x86.tmp output/x86

output/x86_64:
	rm -rf output/x86
	mkdir -p output/x86_64
	./build -j $(CONCURRENCY) -a x86_64 runtime/x86_64 output/x86_64.tmp
	rm -rf runtime/x86_64
	mv output/x86_64.tmp output/x86_64

upload: $(PACKAGE)-x86.tar.gz $(PACKAGE)-x86_64.tar.gz
	s3cmd -P put $(PACKAGE)-x86.tar.gz $(PACKAGE)-x86_64.tar.gz s3://traveling-ruby/releases/
