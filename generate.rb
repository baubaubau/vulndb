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

  opts.on('--plugin-list [NUMBER_OF_ITEMS]', '--pl', Integer,
          'Generate a new plugins.txt file (supply number of *items* to parse, default : 1500)'
  ) do |value|
    options[:plugin_list] = value
  end

  opts.on('--full-plugin-list', '--fpl', 'Generate a new full plugins.txt file') do |_|
    options[:full_plugin_list] = true
  end

  opts.on('--theme-list [NUMBER_OF_ITEMS]', '--tl', Integer,
          'Generate a new themes.txt file (supply number of *items* to parse, default : 200)'
  ) do |value|
    options[:theme_list] = value
  end

  opts.on('--full-theme-list', '--ftl', 'Generate a new full themes.txt file') do |_|
    options[:full_theme_list] = true
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

p options

if options.key?(:plugin_list) || options[:all]
  most_popular('plugin', options[:plugin_list] || 1500, options[:verbose])
end

full('plugin', options[:verbose]) if options[:full_plugin_list] || options[:all]

if options.key?(:generate_theme_list) || options[:all]
  most_popular('theme', options[:theme_list] || 200, options[:verbose])
end

full('theme', options[:verbose]) if options[:full_theme_list] || options[:all]

if options[:checksums]
  puts '[+] Creating Checksums ...'

  Dir[File.join(DB_DIR, '*.{xml,xsd,txt}')].each do |file|
    puts "  [+] Generating checksum for #{file}" if options[:verbose]
    write_checksum(file)
  end
  puts '[+] Done.'
end
