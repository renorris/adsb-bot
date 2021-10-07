require 'discordrb'
require 'http'
require 'securerandom'
require 'json'
require 'sqlite3'

require_relative 'adsbexchange/adsbx'
require_relative 'utils'

@bot = Discordrb::Commands::CommandBot.new token: File.read('token.txt'), prefix: '-'
@adsbx = ADSBx::API.new

@bot.ready do |event|
  puts 'Ready event fired'
end

@bot.command :time do |event|
  event.channel.start_typing
  # Commands send whatever is returned from the block to the channel. This allows for compact commands like this,
  # but you have to be aware of this so you don't accidentally return something you didn't intend to.
  # To prevent the return value to be sent to the channel, you can just return `nil`.
  Time.now
end

@bot.command :plane do |event, arg|
  event.channel.start_typing
  rv = @adsbx.get_recent_trace(arg)
  return rv[1] unless rv[0]

  json = rv[1]
  last_trace = rv[1]['trace'][-1]
  seconds_since_last_seen = (Time.now - Time.at(json['timestamp'].to_i + last_trace[0].to_i)).to_i
  thumbnail_url = 'https://www.adsbexchange.com/wp-content/uploads/Stealth.png'

  event.channel.send_embed do |embed|
    embed.title = json['r']
    embed.description = "A #{json["year"]} #{json["desc"]} (#{json["t"]}) owned by #{json["ownOp"]}"
    embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: thumbnail_url)
    embed.add_field(name: 'Location', value: "#{last_trace[1]}, #{last_trace[2]}", inline: false)
    embed.add_field(name: 'Altitude', value: last_trace[3], inline: false)
    embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "Last seen #{Utils.pretty_print_duration(seconds_since_last_seen)} ago")
  end

  return nil
end

@bot.command :since do |event, arg|
  event.channel.start_typing
  planes = File.read('planelist.txt').split("\n")
  time_arg = Time.parse(arg)
  flagged_planes = {}

  planes.each do |n_number|
    rv = @adsbx.get_recent_trace(n_number)
    if rv[0]
      seconds_since_last_seen = (Time.now - (Time.at(rv[1]['timestamp'].to_i + rv[1]['trace'][-1][0].to_i))).to_i
      seconds_since_time_arg = Time.now.to_i - time_arg.to_i
      if seconds_since_last_seen < seconds_since_time_arg
        flagged_planes[n_number] = seconds_since_last_seen
      end
    end
  end

  if flagged_planes.empty?
    return 'No activity found for that time range'
  end

  response_body = ''
  flagged_planes.each do |n_number, seconds|
    response_body += "#{n_number} - #{Utils::pretty_print_duration(seconds)} ago\n"
  end

  event.channel.send_embed do |embed|
    embed.title = "Activity since #{time_arg}"
    embed.description = "```#{response_body}```"
  end

  return nil
end

@bot.run
