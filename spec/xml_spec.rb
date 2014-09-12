# encoding: UTF-8

require 'nokogiri'
require 'rspec/its'

describe 'XSD checks' do

  after :each do
    expect(FileTest.exists?(@file)).to be_truthy

    xsd = Nokogiri::XML::Schema(File.read(@xsd))
    doc = Nokogiri::XML(File.read(@file))

    errors = []
    xsd.validate(doc).each do |error|
      errors << "#{@file}:#{error.line}: #{error.message}"
    end

    fail errors.join("\n") unless errors.empty?
  end

  it 'check wp_versions.xml for syntax errors' do
    @file = 'wp_versions.xml'
    @xsd  = 'wp_versions.xsd'
  end

  it 'check local_vulnerable_files.xml for syntax errors' do
    @file = 'local_vulnerable_files.xml'
    @xsd  = 'local_vulnerable_files.xsd'
  end
end

describe 'Well formed XML checks' do
  after :each do
    expect(FileTest.exists?(@file)).to be_truthy

    begin
      Nokogiri::XML(File.open(@file)) { |config| config.options = Nokogiri::XML::ParseOptions::STRICT }
    rescue Nokogiri::XML::SyntaxError => e
      raise "#{@file}:#{e.line},#{e.column}: #{e.message}"
    end
  end

  it 'check wp_versions.xml for syntax errors' do
    @file = 'wp_versions.xml'
  end

  it 'check local_vulnerable_files.xml for syntax errors' do
    @file = 'local_vulnerable_files.xml'
  end
end
