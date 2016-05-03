require "rubygems"
require "bundler"

Bundler.require 

require_relative "lib/routes"
run Sinatra::Application
