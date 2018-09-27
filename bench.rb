require "discordrb"
require "benchmark/ips"

# stubs
class Discordrb::Bot
  def user(id)
    [:user, id]
  end

  def channel(id, server = nil)
    [:channel, id]
  end

  def emoji(id)
    [:emoji, id]
  end

  def parse_mentions_regex(mentions, server = nil)
    array_to_return = []
    while mentions.include?('<') && mentions.include?('>')
      mentions = mentions.split('<', 2)[1]
      next unless mentions.split('>', 2).first.length < mentions.split('<', 2).first.length
      mention = mentions.split('>', 2).first
      if /@!?(?<id>\d+)/ =~ mention
        array_to_return << user(id) unless user(id).nil?
      elsif /#(?<id>\d+)/ =~ mention
        array_to_return << channel(id, server) unless channel(id, server).nil?
      elsif /@&(?<id>\d+)/ =~ mention
        if server
          array_to_return << server.role(id) unless server.role(id).nil?
        else
          @servers.values.each do |element|
            array_to_return << element.role(id) unless element.role(id).nil?
          end
        end
      elsif /(?<animated>^[a]|^${0}):(?<name>\w+):(?<id>\d+)/ =~ mention
        array_to_return << (emoji(id) || Emoji.new({ 'animated' => !animated.nil?, 'name' => name, 'id' => id }, self, nil))
      end
    end
    array_to_return
  end
end

class Server
  def role(id)
    [:role, id]
  end
end

server = Server.new


# benchmark
bot = Discordrb::Bot.new(token: "token")

string = "<@123456789> <@!123456789> <#123456789> <@&123456789> <a:foo:123456789> <:foo:123456789>"

Benchmark.ips do |x|
  x.report("custom parser") do
    bot.parse_mentions(string, server)
  end

  x.report("regex") do
    bot.parse_mentions_regex(string, server)
  end

  x.compare!
end
