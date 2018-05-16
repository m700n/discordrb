module Discordrb::Middleware
  # A stock middleware that allows usage of event handler classes from `Events`
  # to be used in middleware chains.
  # @!visibility private
  class HandlerMiddleware
    def initialize(handler)
      @handler = handler
    end

    # Handle events
    def call(event, _state)
      yield if @handler.matches?(event)
    end
  end
end
