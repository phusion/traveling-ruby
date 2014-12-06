VERSION := $(shell cat ../VERSION.txt)
RUBY_VERSION := $(shell cat ../RUBY_VERSION.txt)

PACKAGE := traveling-ruby-$(VERSION)-$(RUBY_VERSION)-linux
CONCURRENCY := 2

.PHONY: package upload

package: $(PACKAGE)-x86.tar.gz $(PACKAGE)-x86_64.tar.gz

$(PACKAGE)-x86.tar.gz: runtime/x86/ok output/x86/bin
	cd output/x86 && env GZIP=--best tar -czf ../../$(PACKAGE)-x86.tar.gz *

$(PACKAGE)-x86_64.tar.gz: runtime/x86_64/ok output/x86_64/bin
	cd output/x86_64 && env GZIP=--best tar -czf ../../$(PACKAGE)-x86_64.tar.gz *

runtime/x86/ok:
	mkdir -p runtime/x86
	./setup-runtime -a x86 runtime/x86
	touch runtime/x86/ok

runtime/x86_64/ok:
	mkdir -p runtime/x86_64
	./setup-runtime -a x86_64 runtime/x86_64
	touch runtime/x86_64/ok

output/x86/bin:
	mkdir -p output/x86
	./build -j $(CONCURRENCY) -a x86 runtime/x86 output/x86

output/x86_64/bin:
	mkdir -p output/x86_64
	./build -j $(CONCURRENCY) -a x86_64 runtime/x86_64 output/x86_64

upload: $(PACKAGE)-x86.tar.gz $(PACKAGE)-x86_64.tar.gz
	./upload $(PACKAGE)-x86.tar.gz $(PACKAGE)-x86_64.tar.gz
