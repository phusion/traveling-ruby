# Traveling-Ruby Standalone Installation


## From GitHub Release Page


## Standalone Installer


  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/you54f/traveling-ruby/next-test/cli.sh)" 


```console
/bin/sh -c 'curl -fsSL https://gist.githubusercontent.com/YOU54F/2e47eb0b653b6810dd6a0be9fc6820ea/raw/install.sh' | sh -s -- --help
Usage: sh [-v <version>] [-d <release-date>] [--set-path] [--clean-install] [--ci]

  -v <version>          Ruby version to install (default: 3.2.2)
  -d <release-date>     Release date of the traveling ruby package to download (default: latest)
  --set-path            Add the traveling ruby bin path to the PATH environment variable (default: false)
  --clean-install       Remove any existing traveling ruby installation before installing (default: false)
  --ci                  Set --set-path to true and --clean-install to true (default: false)
```


```yml
on: 
  workflow_dispatch:
  push:
  
jobs:
  test_github_action:
    strategy:
      matrix:
        os: [ubuntu-latest,windows-latest,macos-latest]
      fail-fast: false
    runs-on: ${{ matrix.os }}
    name: test pact cli action
    steps:
      - uses: actions/checkout@v3
      - run: /bin/sh -c 'curl -fsSL https://raw.githubusercontent.com/you54f/traveling-ruby/next-test/cli.sh' | sh -s -- --ci -v 2.6.10
      - run: ruby --version
```

## GitHub Actions

```yml
on: 
  workflow_dispatch:
  push:
  
jobs:
  test_github_action:
    strategy:
      matrix:
        os: [ubuntu-latest,windows-latest,macos-latest]
      fail-fast: false
    runs-on: ${{ matrix.os }}
    name: test pact cli action
    steps:
      - uses: actions/checkout@v3
      - uses: you54f/traveling-ruby@next-test
      - run: ruby --version
```


## Docker Images

https://hub.docker.com/r/you54f/traveling-ruby/tags


docker run --platform=linux/arm64 --rm -it you54f/traveling-ruby:3.3.0-preview1 --version
docker run --platform=linux/amd64 --rm -it you54f/traveling-ruby:3.3.0-preview1 --version
docker run --platform=linux/arm64 --rm -it you54f/traveling-ruby:3 --version
docker run --platform=linux/amd64 --rm -it you54f/traveling-ruby:3 --version
docker run --platform=linux/arm64 --rm -it you54f/traveling-ruby:3.1 --version
docker run --platform=linux/amd64 --rm -it you54f/traveling-ruby:3.1 --version
docker run --platform=linux/arm64 --rm -it you54f/traveling-ruby:3.0 --version
docker run --platform=linux/amd64 --rm -it you54f/traveling-ruby:3.0 --version
docker run --platform=linux/arm64 --rm -it you54f/traveling-ruby:2.6.10 --version
docker run --platform=linux/amd64 --rm -it you54f/traveling-ruby:2.6.10 --version