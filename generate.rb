#!/usr/bin/env ruby

require 'optparse'
require 'typhoeus'
require_relative 'lib'

DB_DIR = File.expand_path(File.dirname(__FILE__))

options = {}

OptionParser.new do |opts|
  opts.on('-v', '--verbose', 'Run verbosely') do |_|
    options[:verbose] = true
  end

  opts.on('--plugins [NUMBER_OF_ITEMS]', '-p', Integer,
          'Generate a new plugins.txt file (supply number of *items* to parse, default : 1500)'
  ) do |value|
    options[:plugins] = value
  end

  opts.on('--full-plugins', '-P', 'Generate a new full plugins.txt file') do |_|
    options[:full_plugins] = true
  end

  opts.on('--themes [NUMBER_OF_ITEMS]', '-t', Integer,
          'Generate a new themes.txt file (supply number of *items* to parse, default : 200)'
  ) do |value|
    options[:themes] = value
  end

  opts.on('--full-themes', '-T', 'Generate a new full themes.txt file') do |_|
    options[:full_themes] = true
  end

  opts.on('--all', '-a',
          'Generate a new full plugins, full themes, popular plugins and popular themes list'
  ) do |_|
    options[:all] = true
  end

  opts.on('--checksums', '-c', 'Generate the checksums for all files except the json ones') do |_|
    options[:checksums] = true
  end
end.parse!

if options.key?(:plugins) || options[:all]
  most_popular('plugin', options[:plugins] || 1500, options[:verbose])
end

full('plugin', options[:verbose]) if options[:full_plugins] || options[:all]

if options.key?(:themes) || options[:all]
  most_popular('theme', options[:themes] || 200, options[:verbose])
end

full('theme', options[:verbose]) if options[:full_themes] || options[:all]

if options[:checksums]
  puts '[+] Creating Checksums ...'

  Dir[File.join(DB_DIR, '*.{xml,xsd,txt}')].each do |file|
    puts "  [+] Generating checksum for #{file}" if options[:verbose]
    write_checksum(file)
  end
  puts '[+] Done.'
end
