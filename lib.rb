def most_popular(type, number_of_items, verbose = false)
  puts "[+] Generating new most popular #{type} list (#{number_of_items} items)"
  puts
  GenerateList.new(type + 's', verbose).generate_popular_list(number_of_items)
end

def full(type, verbose = false)
  puts "[+] Generating new full #{type} list"
  puts
  GenerateList.new(type + 's', verbose).generate_full_list
end

def write_checksum(file)
  File.write("#{file}.sha512", Digest::SHA512.file(file).hexdigest)
end

#
## Classes
#

# This Class Parses SVN Repositories via HTTP
class SvnParser
  attr_accessor :verbose, :svn_root, :keep_empty_dirs

  def initialize(svn_root)
    @svn_root = svn_root
  end

  def parse
    root_directories
  end

  private

  # Gets all directories in the SVN root
  def root_directories
    dirs      = []
    rootindex = Typhoeus.get(@svn_root).body

    rootindex.scan(%r{<li><a href=".+">(.+)/</a></li>}i).each do |dir|
      dirs << dir[0]
    end

    dirs.sort!
    dirs.uniq
  end
end

# This tool generates a list to use for plugin and theme enumeration
class GenerateList
  attr_accessor :verbose

  # type = themes | plugins
  def initialize(type, verbose)
    if type =~ /plugins/i
      @type           = 'plugin'
      @svn_url        = 'http://plugins.svn.wordpress.org/'
      @popular_url    = 'http://api.wordpress.org/plugins/info/1.0/'
      @popular_action = 'query_plugins'
    elsif type =~ /themes/i
      @type           = 'theme'
      @svn_url        = 'http://themes.svn.wordpress.org/'
      @popular_url    = 'http://api.wordpress.org/themes/info/1.0/'
      @popular_action = 'query_themes'
    else
      fail "Type #{type} not defined"
    end
    @verbose = verbose
  end

  def file_name(type)
    case @type
    when 'plugin'
      case type
      when :full
        @file_name = 'plugins_full.txt'
      when :popular
        @file_name = 'plugins.txt'
      else
        fail 'Unknown type'
      end
    when 'theme'
      case type
      when :full
        @file_name = 'themes_full.txt'
      when :popular
        @file_name = 'themes.txt'
      else
        fail 'Unknown type'
      end
    else
      fail "Unknown type #{@type}"
    end
  end

  def generate_full_list
    file_name(:full)
    items = SvnParser.new(@svn_url).parse
    save(items)
  end

  def generate_popular_list(items)
    file_name(:popular)
    items = popular_items(items)
    save(items)
  end

  def request_params
    {
      timeout: 20_000,
      connecttimeout: 20_000,
      cache_ttl: 0
    }
  end

  # Fets most popular items via unofficial wordpress api
  # see https://github.com/wpscanteam/wpscan/issues/657
  def popular_items(items)
    found_items = []

    # in chunks of 100
    step = 100
    number_of_requests = (items.to_f / step.to_f).ceil
    counter = 1
    while items > 0
      puts "[+] Request #{counter} / #{number_of_requests}"
      rest = items < step ? items : step

      # we need to fetch step entries every time, because the starting page
      # is calculated: page * entries per page. If we would reduce the
      # per page entries, the starting point will not match. So we are
      # stripping down the array later
      post_data = get_serialized(counter, step)
      params    = request_params.merge(body: { action: @popular_action, request: post_data })
      resp      = Typhoeus.post(@popular_url, params)

      fail "Unknown reponse (code #{resp.code})" unless resp.code == 200
      found = resp.body.scan(/"slug";s:[0-9]+:"([^"]+)";/).flatten

      # too much entries? remove them
      found = found[0, rest] if found.length > rest

      found_items << found

      items -= rest
      counter += 1
    end

    found_items.flatten!
    found_items.sort!
    found_items.uniq
  end

  # Save the file
  def save(items)
    items.sort!
    items.uniq!

    puts "[*] We have parsed #{items.length} #{@type}s"
    File.open(@file_name, 'w') { |f| f.puts(items) }
    puts "New #{@file_name} file created"

    puts '[+] Creating checksum'
    write_checksum(@file_name)
    puts
  end

  private

  def get_serialized(page_start, count)
    'O:8:"stdClass":4:{s:4:"page";i:' + page_start.to_s + ';s:8:"per_page";i:' + count.to_s + ';s:6:"browse";s:7:"popular";s:6:"fields";a:9:{s:11:"description";b:0;s:8:"sections";b:0;s:6:"tested";b:0;s:8:"requires";b:0;s:6:"rating";b:0;s:12:"downloadlink";b:0;s:12:"last_updated";b:0;s:8:"homepage";b:0;s:4:"tags";b:0;}}'
  end
end
