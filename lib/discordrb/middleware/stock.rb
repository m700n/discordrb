module Discordrb::Middleware
  # Module for describing stock middleware handlers and generating middleware
  # chains from a hash. This can be used to extend the default event handler
  # attributes with custom ones.
  # @example Add a role name attribute to `bot.reaction_add`
  #   Discordrb::Middleware::Stock.register(:reaction_add, :role_name) do |value|
  #     lambda do |event, _state, &block|
  #       roles = event.user.roles.map(&:name)
  #       block.call if roles.include?(value)
  #     end
  #   end
  #
  #   bot.message(role_name: 'No Reactions') do |event|
  #     event.message.delete_reaction(event.user, event.emoji)
  #   end
  module Stock
    module_function

    @middleware = Hash.new { |hash, key| hash[key] = {} }

    def register(name, attribute, &block)
      define_singleton_method(name) do |attributes|
        attributes.map do |key, value|
          middleware = @middleware[name][key]
          raise ArgumentError, "Attribute #{key.inspect} (given with value #{value.inspect}) doesn't exist for #{name} event handlers. Options are: #{@middleware[name].keys}" unless middleware
          middleware.call(value)
        end
      end

      @middleware[name][attribute] = block
    end

    register(:message, :content) do |value|
      lambda do |event, _state, &block|
        block.call if event.content == value
      end
    end

    register(:message, :in) do |value|
      if value.is_a?(String)
        value.delete!('#')
        lambda do |event, _state, &block|
          block.call if event.channel.name == value
        end
      elsif value.is_a?(Integer)
        lambda do |event, _state, &block|
          block.call if event.channel.id == value
        end
      end
    end

    register(:message, :start_with) do |value|
      if value.is_a?(String)
        lambda do |event, _state, &block|
          block.call if event.content.start_with?(value)
        end
      elsif value.is_a?(Regexp)
        lambda do |event, _state, &block|
          content = event.content
          block.call if (content =~ value) && (content =~ value).zero?
        end
      end
    end

    register(:message, :end_with) do |value|
      if value.is_a?(String)
        lambda do |event, _state, &block|
          block.call if event.content.end_with?(value)
        end
      elsif value.is_a?(Regexp)
        lambda do |event, _state, &block|
          content = event.content
          # BUG: Doesn't work without a group
          block.call if value.match(content) ? content.end_with?(value.match(content)[-1]) : false
        end
      end
    end

    register(:message, :contains) do |value|
      if value.is_a?(String)
        lambda do |event, _state, &block|
          block.call if event.content.include?(value)
        end
      elsif value.is_a?(Regexp)
        lambda do |event, _state, &block|
          content = event.content
          block.call if value =~ content
        end
      end
    end

    register(:message, :from) do |value|
      if value.is_a?(String)
        lambda do |event, _state, &block|
          block.call if event.author.name == value
        end
      elsif value.is_a?(Integer)
        lambda do |event, _state, &block|
          block.call if event.author.id == value
        end
      elsif value == :bot
        lambda do |event, _state, &block|
          block.call if event.author.current_bot?
        end
      end
    end

    register(:message, :after) do |value|
      lambda do |event, _state, &block|
        block.call if event.timestamp > value
      end
    end

    register(:message, :before) do |value|
      lambda do |event, _state, &block|
        block.call if event.timestamp < value
      end
    end

    register(:message, :private) do |value|
      lambda do |event, _state, &block|
        block.call if !event.channel.private? == !value
      end
    end
  end
end
