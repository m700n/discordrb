# frozen-string-literal: true

module Discordrb
  # :nodoc:
  class MentionParser
    attr_reader :current_char

    def next_char
      @current_char = @reader.getc
    end

    def peek_next_char
      @reader.string[@reader.pos]
    end

    def parse(str)
      @reader = StringIO.new(str)

      loop do
        char = @reader.getc
        break unless char
        case char
        when '@'
          next_char
          if current_char == 'e' || current_char == 'h'
            string = consume_ascii
            yield [:everyone] if string == 'everyone'
            yield [:here] if string == 'here'
          end
        when '<'
          next_char
          case current_char
          when '@'
            next_char

            kind = :user

            if current_char == '!'
              kind = :user
              next_char
            end

            if current_char == '&'
              kind = :role
              next_char
            end

            id = consume_id
            yield [kind, id] if current_char == '>'
          when '#'
            next_char
            kind = :channel
            id = consume_id
            yield [kind, id] if current_char == '>'
          when ':', 'a'
            next if current_char == 'a' && peek_next_char != ':'

            kind = :emoji
            animated = false

            if current_char == 'a'
              animated = true
              next_char
            end

            if current_char == ':'
              next_char
              name = consume_ascii
              if current_char == ':'
                next_char
                id = consume_id
                yield [kind, animated, name, id] if current_char == '>'
              end
            end
          end
        end
      end
    end

    def current_ascii_letter?
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMOPQRSTUVWXYZ'.include?(current_char)
    end

    def current_number?
      '0123456789'.include?(current_char)
    end

    def consume_ascii
      start = @reader.pos
      length = 0
      loop do
        break unless current_char && current_ascii_letter?
        next_char
        length += 1
      end
      @reader.string.slice(start - 1, length)
    end

    def consume_id
      start = @reader.pos
      length = 0
      loop do
        break unless current_char && current_number?
        next_char
        length += 1
      end

      begin
        id = @reader.string.slice(start - 1, length)
        Integer(id)
      rescue ArgumentError
        nil
      end
    end
  end
end
