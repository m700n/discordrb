module Discordrb::Middleware
  # Internal class that holds a chain of middleware.
  # @!visibility private
  class Stack
    def initialize(middleware)
      @middleware = middleware
    end

    # Runs an event object across this chain of middleware and optional block
    def run(event, state = {}, index = 0, &block)
      middleware = @middleware[index]
      if middleware
        state[middleware.class] = middleware
        middleware.call(event, state) { run(event, state, index + 1, &block) }
      elsif block_given?
        yield event, state
      end
    end
  end
end
