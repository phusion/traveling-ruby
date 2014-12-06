VERSION := $(shell cat ../VERSION.txt)
RUBY_VERSION := $(shell cat ../RUBY_VERSION.txt)

PACKAGE := traveling-ruby-$(VERSION)-$(RUBY_VERSION)-osx

.PHONY: package upload

package: $(PACKAGE).tar.gz

$(PACKAGE).tar.gz: runtime output
	cd output && env GZIP=--best tar -czf ../$(PACKAGE).tar.gz *

runtime:
	./setup-runtime runtime

output:
	./build runtime output

upload: $(PACKAGE).tar.gz
	s3cmd -P put $(PACKAGE).tar.gz s3://traveling-ruby/releases/
