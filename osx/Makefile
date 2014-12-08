VERSION := $(shell cat ../VERSION.txt)
RUBY_VERSION := $(shell cat ../RUBY_VERSION.txt)

PACKAGE := traveling-ruby-$(VERSION)-$(RUBY_VERSION)-osx.tar.gz
GEM_DIR := traveling-ruby-gems-$(VERSION)-$(RUBY_VERSION)-osx

.PHONY: package upload clean clean-all

package: $(PACKAGE) $(GEM_DIR)

$(PACKAGE): runtime/ok output/bin
	./package -r $(PACKAGE) output

$(GEM_DIR): runtime/ok output/bin
	./package -E $(GEM_DIR) output

runtime/ok:
	./setup-runtime runtime
	touch runtime/ok

output/bin:
	mkdir -p output
	./build runtime output

upload: $(PACKAGE) $(GEM_DIR)
	s3cmd -P sync --no-preserve $(PACKAGE) s3://traveling-ruby/releases/
	s3cmd -P --delete-removed --no-preserve sync $(GEM_DIR) s3://traveling-ruby/releases/$(GEM_DIR)/

clean:
	rm -rf $(PACKAGE) $(GEM_DIR) output

clean-all: clean
	rm -rf runtime output
