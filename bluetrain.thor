#!/usr/bin/env ruby
$: << File.expand_path("../lib/", __FILE__)
require 'thor'
require 'bluetrain'

Bluetrain.start(ARGV)