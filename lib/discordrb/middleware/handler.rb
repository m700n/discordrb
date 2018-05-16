module Discordrb::Middleware
  # Internal class that allows `Stack` instances to be used inside of a `Bot`s
  # event loop.
  # @!visibility private
  class Handler
    def initialize(stack, block)
      @stack = stack
      @block = block
    end

    # Conditional event matching is handled by middleware themselves,
    # so a `Handler` matches on all events.
    def matches?(_event)
      true
    end

    # Executes the stack with the given event
    def call(event)
      @stack.run(event, &@block)
    end

    # TODO: Make some use of this?
    def after_call(event); end
  end
end
