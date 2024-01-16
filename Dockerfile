FROM ubuntu:22.04

RUN apt-get update && \
      apt-get install -y curl && \
      apt-get clean && rm -rf /var/lib/apt/lists

ARG TRAVELING_RUBY_VERSION=2.6.10
ARG TRAVELING_RUBY_PKG_DATE=20240116
ARG TRAVELING_RUBY_GH_SOURCE=YOU54F/traveling-ruby 

ENV PATH="/home/.traveling-ruby/bin:$PATH"

RUN mkdir /home/.traveling-ruby && \
      if [ "$(uname -m)" = 'aarch64' ] ; then \
            TRAVELING_RUBY_PLATFORM=linux-arm64; \
      else \
            TRAVELING_RUBY_PLATFORM=linux-x86_64; \
      fi && \
      TRAVELING_RUBY_FILENAME=traveling-ruby-${TRAVELING_RUBY_PKG_DATE}-${TRAVELING_RUBY_VERSION}-${TRAVELING_RUBY_PLATFORM} && \
      curl -L https://github.com/${TRAVELING_RUBY_GH_SOURCE}/releases/download/rel-${TRAVELING_RUBY_PKG_DATE}/$TRAVELING_RUBY_FILENAME.tar.gz | \
      tar -xz -C /home/.traveling-ruby

RUN ruby --version

ENTRYPOINT [ "ruby" ]