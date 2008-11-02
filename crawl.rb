#!/opt/local/bin/ruby

require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'eventmachine'
require 'uri'

doc = Hpricot(open('http://news.ycombinator.com/'))
news_links = doc.search('a[@href^=http]').reject {|x| x[:href].include?('ycombinator.com') || x[:href].include?('economist.com') }

def strip_html(html)
  return ''
  return Hpricot(html).inner_text.gsub(/\n|\t|\r/, " ").gsub(/  */, " ")
end



word_counts = File.open "wcs.txt", File::RDWR, File::APPEND
storage_directory = './news-yc-corpus/'

EM.run {
  news_links.each {|nl| 
    begin
      uri = URI::parse(nl[:href].gsub(' ', ''))
      req = EM::Protocols::HttpClient2.connect(uri.host, 80).get(uri.request_uri)
      req.callback {
        text_from_site = strip_html(req.content)
        begin
          html_file = File.new storage_directory + uri.to_s.gsub(/[\/:&?]/, '_'), File::RDWR | File::TRUNC | File::CREAT
          html_file.puts text_from_site
        ensure
          html_file.close
        end
        word_count = text_from_site.split(" ").length
        word_counts.puts [word_count.to_s, uri.to_s + uri.to_s.gsub(/[\/:&?]/, '_')].join(' ')
      }
    rescue URI::InvalidURIError
      ;
    end
  }
}
