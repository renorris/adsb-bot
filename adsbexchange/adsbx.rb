require 'securerandom'
require 'http'
require 'json'

require_relative 'adsbx_utils'

module ADSBx
  class API
    def initialize
      @cookie = gen_cookie
      validate_cookie(@cookie)
      @cookie_last_updated = Time.now
      @cookie_mutex = Mutex.new
    end

    def get_recent_trace(n_number)
      rv = ADSBx::Utils.hex_for_n_number(n_number)
      hex = ''
      if rv[0]
        hex = rv[1]
      else
        return [false, 'Unknown n-number']
      end

      response = HTTP.headers('Accept' => '*/*',
                              'Accept-Encoding' => 'application/json',
                              'Accept-Languagte' => 'en-US,en;q=0.9',
                              'Cookie' => "adsbx_sid=#{get_current_cookie}",
                              'Referer' => 'https://globe.adsbexchange.com/',
                              'Sec-Fetch-Dest' => 'empty',
                              'Sec-Fetch-Mode' => 'cors',
                              'Sec-Fetch-Site' => 'same-origin',
                              'Sec-Gpc' => '1',
                              'User-Agent' => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:15.0) Gecko/20100101 Firefox/15.0.1',
                              'X-Requested-With' => 'XMLHttpRequest')
                     .get("https://globe.adsbexchange.com/data/traces/#{hex[4..5]}/trace_recent_#{hex}.json")

      unless response.status.success?
        return [false, "Could not pull aircraft data, most likely >24hrs since it's flown"]
      end

      [true, JSON.parse(response)]
    end

    private

    def get_current_cookie
      r_cookie = ''
      @cookie_mutex.synchronize do
        if (Time.now.to_i - @cookie_last_updated.to_i) > 1800 # 30min * 60sec
          @cookie = gen_cookie
          validate_cookie(@cookie)
          @cookie_last_updated = Time.now
        end
        r_cookie = @cookie.dup
      end
      r_cookie
    end

    def gen_cookie
      "#{(Time.now.to_f * 1000).to_i + 2 * 86400 * 1000}_#{SecureRandom.hex(16)[0..10]}"
    end

    def validate_cookie(cookie)
      HTTP.headers('Accept' => '*/*',
                   'Accept-Encoding' => 'application/json',
                   'Accept-Languagte' => 'en-US,en;q=0.9',
                   'Cookie' => "adsbx_sid=#{cookie}",
                   'Referer' => 'https://globe.adsbexchange.com/',
                   'Sec-Fetch-Dest' => 'empty',
                   'Sec-Fetch-Mode' => 'cors',
                   'Sec-Fetch-Site' => 'same-origin',
                   'Sec-Gpc' => '1',
                   'User-Agent' => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:15.0) Gecko/20100101 Firefox/15.0.1',
                   'X-Requested-With' => 'XMLHttpRequest')
          .get('https://globe.adsbexchange.com/globeRates.json')
    end
  end
end


