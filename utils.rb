module Utils
  def self.pretty_print_duration(secs)
    mins = secs / 60
    hours = mins / 60
    days = hours / 24

    if days > 0
      "#{days} days and #{hours % 24} hours"
    elsif hours > 0
      "#{hours} hours and #{mins % 60} minutes"
    elsif mins > 0
      "#{mins} minutes and #{secs % 60} seconds"
    elsif secs >= 0
      "#{secs} seconds"
    end
  end

  def self.get_aircraft_thumbnail_url(hex)
    # https://www.airport-data.com/api/ac_thumb.json?m=400A0B&n=2
    apd = JSON.parse(HTTP.get("https://www.airport-data.com/api/ac_thumb.json?m=#{hex}&n=1"))
    thumbnail_url = 'https://www.adsbexchange.com/wp-content/uploads/Stealth.png'
    if apd['status'] == 200 && apd['count'] > 0
      thumbnail_url = apd['data'][0]['image']
    end
    thumbnail_url
  end
end