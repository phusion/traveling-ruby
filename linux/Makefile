VERSION := $(shell cat ../VERSION.txt)
RUBY_VERSION := $(shell cat ../RUBY_VERSION.txt)

PACKAGE := traveling-ruby-$(VERSION)-$(RUBY_VERSION)-linux
GEM_DIR := traveling-ruby-gems-$(VERSION)-$(RUBY_VERSION)-linux
CONCURRENCY := $(shell ./internal/cpucount)

.PHONY: package upload clean clean-all

package: $(PACKAGE)-x86.tar.gz $(PACKAGE)-x86_64.tar.gz $(GEM_DIR)-x86 $(GEM_DIR)-x86_64

$(PACKAGE)-x86.tar.gz: runtime/x86/ok output/x86/bin
	./package -r $(PACKAGE)-x86.tar.gz output/x86

$(PACKAGE)-x86_64.tar.gz: runtime/x86_64/ok output/x86_64/bin
	./package -r $(PACKAGE)-x86_64.tar.gz output/x86_64

$(GEM_DIR)-x86: output/x86/bin
	./package -E $(GEM_DIR)-x86 output/x86

$(GEM_DIR)-x86_64: output/x86_64/bin
	./package -E $(GEM_DIR)-x86_64 output/x86_64

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
	./upload $(PACKAGE)-x86.tar.gz $(PACKAGE)-x86_64.tar.gz $(GEM_DIR)-x86 $(GEM_DIR)-x86_64

clean:
	rm -rf $(PACKAGE)-x86.tar.gz $(PACKAGE)-x86_64.tar.gz $(GEM_DIR)-x86 $(GEM_DIR)-x86_64

clean-all: clean
	sudo rm -rf runtime
	rm -rf output
