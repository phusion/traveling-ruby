VERSION := $(shell cat ../VERSION.txt)
RUBY_VERSION := $(shell cat ../RUBY_VERSION.txt)

PACKAGE := traveling-ruby-$(VERSION)-$(RUBY_VERSION)-osx.tar.gz
GEM_DIR := traveling-ruby-gems-$(VERSION)-$(RUBY_VERSION)-osx

.PHONY: package upload clean clean-all

package: $(PACKAGE) $(GEM_DIR)

$(PACKAGE).tar.gz: runtime output
	./package -r $(PACKAGE) output

$(GEM_DIR): runtime output
	./package -E $(GEM_DIR) output

runtime:
	./setup-runtime runtime

output:
	./build runtime output

upload: $(PACKAGE)
	s3cmd -P put $(PACKAGE) s3://traveling-ruby/releases/
	s3cmd -P --delete-removed sync $(GEM_DIR) s3://traveling-ruby/releases/$(GEM_DIR)/

clean:
	rm -rf $(PACKAGE) $(GEM_DIR)

clean-all: clean
	rm -rf runtime output
