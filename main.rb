# 1. Go to a random page on Wikipedia. The title of the page you land on is the name of your band.
# http://en.wikipedia.org/wiki/Special:Random
# 2. Go to a random quotation. The last four words of the last quote on the page is the title of your album.
# http://www.quotationspage.com/random.php3
# 3. Go to a random picture on Flickr. The third picture is the cover art for your album.
# http://www.flickr.com/explore/interesting/7days/


### Setup
require 'sinatra'
require 'haml'
require 'sass'
require 'json'
require 'nokogiri'
require 'open-uri'
require 'flickraw-cached'
require 'mongo_mapper'

require File.join(File.dirname(__FILE__), 'config', 'flickr.rb')
require File.join(File.dirname(__FILE__), 'config', 'database.rb')

# MongoMapper.connection = Mongo::Connection.new(DB_HOST, 0000, :pool_size => 5, :timeout => 5)
MongoMapper.connection = Mongo::Connection.new(DB_HOST)
MongoMapper.database = DB_NAME
# MongoMapper.database.authenticate(DB_USERNAME, DB_PASSWORD)

RANDOM_WIKIPEDIA_ARTICLE_URL = "http://en.wikipedia.org/wiki/Special:Random"
QUOTATIONS_HOSTNAME = "http://www.quotationspage.com"
RANDOM_QUOTATION_URL = "http://www.quotationspage.com/random.php3"

FONTS = [
  'Helvetica',
  'Lobster',
  'Tangerine',
  'Mountains of Christmas',
  'Reenie Beanie',
  'Molengo',
  'Josefin Slab',
  'Yanone Kaffeesatz',
  'Neucha',
  'Geo',
  'Just Me Again Down Here',
  'Raleway',
  'Allerta Stencil',
  'Covered By Your Grace',
  'Orbitron',
  'Sniglet',
  'UnifrakturMaguntia',
  'Syncopate',
  'UnifrakturCook',
  'Vibur',
  'Kenia',
  'Maiden Orange',
  'Kristi',
  'Gruppo',
  'Corben'
]

### Models
class Album
  include MongoMapper::Document
  key :cover_image_url, String
  key :cover_image_photopage, String
  key :band_name, String
  key :title_quote_url, String
  key :title, String
  key :band_font, String
  key :title_font, String
end

### Misc. methods
def get_band_name
  Nokogiri::HTML(open(RANDOM_WIKIPEDIA_ARTICLE_URL)).at_xpath("//h1[@class=\"firstHeading\"]").text
end

def get_album_title(quote)
  quote.text.gsub(/[\.\?\!\'\"]/, "").split(' ')[-4,4].map!{|x| x.capitalize}.join(' ')
end

def get_random_quote
  Nokogiri::HTML(open(RANDOM_QUOTATION_URL)).xpath(".//*[@id='content']/dl/dt[1]/a").first
end

def get_random_image
  list = flickr.interestingness.getList
  list[rand(list.size)]
end

### Controller Actions
get '/' do
  quote = get_random_quote
  image = get_random_image
  @album = Album.new(
    :cover_image_url => FlickRaw.url_z(image),
    :cover_image_photopage => FlickRaw.url_photopage(image),
    :band_name => get_band_name,
    :title_quote => quote.text,
    :title_quote_url => "#{QUOTATIONS_HOSTNAME}#{quote['href']}",
    :title => get_album_title(quote),
    :band_font => FONTS[rand(FONTS.size)],
    :title_font => FONTS[rand(FONTS.size)]
  )
  @album.save
  
  haml :index
end

get '/album/:id' do
  if (@album = Album.find(params[:id]))
    haml :index
  else
    redirect '/', 303
  end
end

# Miscellaneous actions
get '/css/application.css' do
  sass :style
end

# Helpers
helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end