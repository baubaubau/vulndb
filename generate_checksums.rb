#!/usr/bin/env ruby

require 'digest'

# Calculates file checksums and writes them to files.

DB_DIR = File.expand_path(File.dirname(__FILE__))

puts '[+] Creating Checksums ...'

Dir[File.join(DB_DIR, '{*.{xml,xsd,txt},LICENSE}')].each do |file|
  puts "[+] Generating checksum for #{file}"
  File.write("#{file}.sha512", Digest::SHA512.file(file).hexdigest)
end

puts '[+] Done.'

