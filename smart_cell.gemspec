# frozen_string_literal: true
$LOAD_PATH.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "smart_cell/version"

Gem::Specification.new do |s|
  s.name        = "smart-cell"
  s.version     = SmartCell::VERSION

  s.summary     = "Optimize workload with celluloid"
  s.description = "A scheduling middleware for optimizing workload " \
    "by using evented IO in Celluloid."
  s.authors     = ["Matthias Geier"]
  s.email       = "matthias.geier@metoda.com"
  s.homepage    = "https://github.com/metoda/smart_cell"
  s.license     = "BSD-2-Clause"

  s.files       = Dir["lib/**/*.rb", "LICENSE"]
  s.executables = []
  s.add_dependency "celluloid"
  s.add_dependency "celluloid-io"
  #s.test_files  = Dir["test/**/*"]
  #s.add_development_dependency "minitest", "~> 5.10"
end
