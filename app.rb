require 'yaml'
require 'net/http'
require 'http-cookie'
require 'cgi'

class GoldsCheckin
  def initialize
    @config = YAML.load_file('config.yml')
    @jar = HTTP::CookieJar.new
  end

  def login
    uri = URI('https://mico.myiclubonline.com/iclub/j_spring_security_check')

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      req = Net::HTTP::Post.new uri
      req.form_data = { "j_username": @config['username'], "j_password": @config['password'] }
      res = http.request req
      res.get_fields('Set-Cookie').each do |value|
        @jar.parse(value, req.uri)
      end
    end
  end

  def fetch_checkins
    low_date = CGI::escape(Time.now.strftime("%m/%d/%Y"))
    high_date = CGI::escape(Time.now.strftime("%m/%d/%Y"))
    uri = URI("https://mico.myiclubonline.com/iclub/account/checkInHistory.htm?lowDate=#{low_date}&highDate=#{high_date}")

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      req = Net::HTTP::Get.new(uri)
      req['Cookie'] = HTTP::Cookie.cookie_value(@jar.cookies(uri))
      res = http.request req
      res.body
    end
  end


end

golds_checkin = GoldsCheckin.new

golds_checkin.login
puts golds_checkin.fetch_checkins
