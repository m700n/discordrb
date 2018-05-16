# frozen_string_literal: true

require 'discordrb/bot'
require 'discordrb/middleware/stack'
require 'discordrb/middleware/handler'
require 'discordrb/middleware/handler_middleware'

# Module for middleware-related functionality
module Discordrb::Middleware
  # A {MiddlewareBot} is an extension of {Bot} that allows for event handlers
  # that accept chains of custom objects, or *middleware*, that get run *before*
  # your handler.
  #
  # A *middleware* can be *any* `class` that responds to `def call(event, state)`
  # and optionally `yield`s. Whether or not your `call` `yield`s or not determines
  # if the rest of the chain is executed.a
  #
  # In `call`, `event` will be the invoking Discord event, and `state` is an
  # empty hash that you can store anything you like in that will persist across
  # the events execution.
  #
  # You can also access the instances of middleware themselves by `state[MyMiddleware]`.
  #
  # Event attributes can be specified *after* your middleware chain, and they
  # will be evaluated *before* your middleware.
  # @example Basic custom middleware usage
  #   class Prefix
  #     def initialize(prefix)
  #       @prefix = prefix
  #     end
  #
  #     def call(_event, _state)
  #       # Only continue if the message starts with our prefix
  #       yield if event.message.content.start_with?(@prefix)
  #     end
  #   end
  #
  #   class RandomNumber
  #     def call(_event, state)
  #       # Store a random number to access later
  #       state[:number] = rand(1..10)
  #       yield
  #     end
  #   end
  #
  #   # Filter on messages in a channel named "general" that start with "!":
  #   bot.message(Prefix.new('!'), RandomNumber.new, in: 'general') do |event, state|
  #     command = event.message.content.split(' ').first
  #     case command
  #     when '!ping'
  #       event.respond('pong')
  #     when '!random'
  #       # Access our `:number` that `RandomNumber` set for this event:
  #       event.respond("Random number: #{state[:number]}")
  #     else
  #       event.repond("Unknown command, try `!ping` or `!random`")
  #     end
  #   end
  # @example Middleware-only event handler
  #   class RandomWord
  #     def initialize(*words)
  #       @words = words
  #     end
  #
  #     def call(event, _state)
  #       event.respond(@words.sample)
  #     end
  #   end
  #
  #   bot.message(RandomWord.new('Go to bed', 'Write more Ruby bots'),
  #               starts_with: '!random')
  class MiddlewareBot < Discordrb::Bot
    class << self
      # @!macro [attach] event_handler
      #   @method $1(*middleware, **attributes, &block)
      #     Registers an {$2} event handler.
      #     @param [Array<#call>] middleware a list of objects that respond to `#call(event, state, &block)`
      #     @param [Hash] attributes attributes to match for this event (See {EventContainer#$1})
      #     @example
      #       class MyMiddleware
      #         def call(event, state)
      #           event # => $2
      #           state[:foo] = 'bar'
      #           yield
      #         end
      #       end
      #
      #       bot.$1(MyMiddleware.new, attribute: 'foo') do |event, state|
      #         event # => $2
      #         state[:foo] # => 'bar'
      #       end
      # @!visibility private
      def event_handler(name, klass)
        define_method(name) do |*middleware, **attributes, &block|
          unless attributes.empty?
            handler = Discordrb::EventContainer.handler_class(klass).new(attributes, nil)
            middleware.unshift(HandlerMiddleware.new(handler))
          end
          stack = Stack.new(middleware)
          (event_handlers[klass] ||= []) << Handler.new(stack, block)
        end
      end
    end

    # @return [Hash<Event => Array<Handler>>] the event handlers registered on this bot
    def event_handlers
      @event_handlers ||= {}
    end

    event_handler :message, MessageEvent

    event_handler :ready, ReadyEvent

    event_handler :disconnected, DisconnectEvent

    event_handler :heartbeat, HeartbeatEvent

    event_handler :typing, TypingEvent

    event_handler :message_edit, MessageEditEvent

    event_handler :message_delete, MessageDeleteEvent

    event_handler :reaction_add, ReactionAddEvent

    event_handler :reaction_remove, ReactionRemoveEvent

    event_handler :reaction_remove_all, ReactionRemoveAllEvent

    event_handler :presence, PresenceEvent

    event_handler :playing, PlayingEvent

    event_handler :mention, MentionEvent

    event_handler :channel_create, ChannelCreateEvent

    event_handler :channel_update, ChannelUpdateEvent

    event_handler :channel_delete, ChannelDeleteEvent

    event_handler :channel_recipient_add, ChannelRecipientAddEvent

    event_handler :channel_recipient_remove, ChannelRecipientRemoveEvent

    event_handler :voice_state_update, VoiceStateUpdateEvent

    event_handler :member_join, ServerMemberAddEvent

    event_handler :member_update, ServerMemberUpdateEvent

    event_handler :member_leave, ServerMemberDeleteEvent

    event_handler :user_ban, UserBanEvent

    event_handler :user_unban, UserUnbanEvent

    event_handler :server_create, ServerCreateEvent

    event_handler :server_update, ServerUpdateEvent

    event_handler :server_delete, ServerDeleteEvent

    event_handler :server_emoji, ServerEmojiChangeEvent

    event_handler :server_emoji_create, ServerEmojiCreateEvent

    event_handler :server_emoji_delete, ServerEmojiDeleteEvent

    event_handler :server_emoji_update, ServerEmojiUpdateEvent

    event_handler :webhook_update, WebhookUpdateEvent

    event_handler :pm, PrivateMessageEvent

    event_handler :raw, RawEvent

    event_handler :unknown, UnknownEvent
  end
end
