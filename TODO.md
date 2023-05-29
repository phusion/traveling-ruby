RUBY_VERSIONS_TASKS: &RUBY_VERSIONS_TASKS
  - script: rake package:$ARCHITECTURES:3.3.0-preview1
    test: rake testdocker:$ARCHITECTURES:3.3.0-preview1

  # - script: rake package:$ARCHITECTURES:3.2.2
  #   test: rake testdocker:$ARCHITECTURES:3.2.2
# 3.2.2
# | PLATFORM | ARCH   | Working |
# | OSX     | x86_64 |  |
# | OSX     | arm64  |  |
# | Linux   | x86_64 |  |
# | Linux   | arm64  | ✅ |
# | Windows | x86_64 |  |
# | Windows | x86    |  |

  # - script: rake package:$ARCHITECTURES:3.1.4
  #   test: rake testdocker:$ARCHITECTURES:3.1.4

# 3.1.4
# | PLATFORM | ARCH   | Working |
# | OSX     | x86_64 |  |
# | OSX     | arm64  |  |
# | Linux   | x86_64 |  |
# | Linux   | arm64  | X |
# | Windows | x86_64 |  |
# | Windows | x86    |  |


  # - script: rake package:$ARCHITECTURES:3.1.2
  #   test: rake testdocker:$ARCHITECTURES:3.1.2
# 3.1.2
# | PLATFORM | ARCH   | Working |
# | OSX     | x86_64 |  |
# | OSX     | arm64  |  |
# | Linux   | x86_64 |  |
# | Linux   | arm64  | ✅ |
# | Windows | x86_64 |  |
# | Windows | x86    |  |


  # - script: rake package:$ARCHITECTURES:3.0.6
  #   test: rake testdocker:$ARCHITECTURES:3.0.6
# + /tmp/ruby/bin/gem install bundler -v 2.4.10 --no-document
# ERROR:  While executing gem ... (Gem::Exception)
#     OpenSSL is not available. Install OpenSSL and rebuild Ruby (preferred) or use non-HTTPS sources
# rake aborted!

# 3.0.6
# | PLATFORM | ARCH   | Working |
# | OSX     | x86_64 |  |
# | OSX     | arm64  |  |
# | Linux   | x86_64 |  |
# | Linux   | arm64  | X |
# | Windows | x86_64 |  |
# | Windows | x86    |  |

  # - script: rake package:$ARCHITECTURES:3.0.4
  #   test: rake testdocker:$ARCHITECTURES:3.0.4

# 3.0.4
# | PLATFORM | ARCH   | Working |
# | OSX     | x86_64 |  |
# | OSX     | arm64  |  |
# | Linux   | x86_64 |  |
# | Linux   | arm64  | ✅ |
# | Windows | x86_64 |  |
# | Windows | x86    |  |

  # - script: rake package:$ARCHITECTURES:2.7.8
  #   test: rake testdocker:$ARCHITECTURES:2.7.8
# /tmp/ruby-2.7.8/lib/rubygems/core_ext/kernel_require.rb:83:in `require': cannot load such file -- openssl (LoadError)
#         from /tmp/ruby-2.7.8/lib/rubygems/core_ext/kernel_require.rb:83:in `require'
#   - script: rake package:$ARCHITECTURES:2.6.10
#     test: rake testdocker:$ARCHITECTURES:2.6.10
# # 2.6.10
# # | PLATFORM | ARCH   | Working |
# # | OSX     | x86_64 |  |
# # | OSX     | arm64  |  |
# # | Linux   | x86_64 |  |
# # | Linux   | arm64  | ✅ |
# # | Windows | x86_64 |  |
# # | Windows | x86    |  |