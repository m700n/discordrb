# This example demonstrates reaction functionality with discordrb

require 'discordrb'

bot = Discordrb::Bot.new token: 'B0T.T0KEN.here', client_id: 160123456789876543

# This gives the user a random thumbs up or thumbs down reaction
# when they phrase a message like "should i ..?"
bot.message(start_with: 'should i') do |event|
  event.message.react %w(👍 👎).sample
end

bot.run
