require 'scraperwiki'
require 'rss'

ENDPOINT = 'https://www.dgmarket.com/tenders/RssFeedAction.do?locationISO=&keywords=Millennium+Challenge+Account&sub=&noticeType=gpn%2cpp%2cspn%2crfc&language'

def clean_table
  ScraperWiki.sqliteexecute('DELETE FROM data')
rescue SqliteMagic::NoSuchTable
  puts "Data table does not exist yet"
end

def fetch_results
  parse_rss.each do |lead|
    ScraperWiki.save_sqlite(%i(guid), lead)
  end
end

def extract_iso2_code(mca_country_string)
  mca_country_string.match(/country\/(\w\w)/)[1].upcase
end

def extract_country_name(mca_country_string)
  mca_country_string.match(/- ([a-zA-Z ]+)/)[1]
end

def parse_rss
  feed = RSS::Parser.parse(open(ENDPOINT), false)
  feed.items.map do |item|
    categories = item.categories.map(&:content)
    country_blob = categories.delete_at(categories.find_index { |e| e =~ /country\// })
    {
      title: item.title,
      link: item.link,
      description: item.description,
      pubDate: item.pubDate,
      guid: item.guid.content,
      categories: categories.join(','),
      country_code: extract_iso2_code(country_blob),
      country_name: extract_country_name(country_blob)
    }
  end
end

clean_table
fetch_results
