require_relative './lib/version.rb'
Gem::Specification.new do |s|
  s.name        = "markov_twitter"
  s.version     = MarkovTwitter::VERSION
  s.date        = "2017-10-12"
  s.summary     = "markov chains from twitter posts"
  s.description = ""
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["max pleaner"]
  s.email       = 'maxpleaner@gmail.com'
  s.required_ruby_version = '~> 2.3'
  s.homepage    = "http://github.com/maxpleaner/markov_twitter"
  s.files       = Dir["lib/**/*.rb", "bin/*", "**/*.md", "LICENSE"]
  s.require_path = 'lib'
  s.required_rubygems_version = ">= 2.6.13"
  s.executables = Dir["bin/*"].map &File.method(:basename)
  s.license     = 'MIT'

  # Dependencies are added here, not the Gemfile.
  s.add_dependency "thor"
  s.add_dependency "twitter"
  s.add_dependency "activesupport"
  s.add_development_dependency "pry"
  s.add_development_dependency "dotenv"
  s.add_development_dependency "rspec"

end
