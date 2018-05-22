require 'discordrb'
require 'discordrb/middleware/middleware_bot'

module Discordrb::Middleware
  describe Stack do
    describe '#run' do
      it 'calls each middleware' do
        a_called = false
        b_called = false

        middleware = [
          lambda do |_, _, &block|
            a_called = true
            block.call
          end,
          lambda do |_, _, &block|
            b_called = true
            block.call
          end
        ]
        stack = described_class.new(middleware)
        stack.run(double)

        expect(a_called && b_called).to eq true
      end

      it "stops when a middleware doesn't yield" do
        a_called = false
        b_called = false

        middleware = [
          lambda do |_, _|
            a_called = true
          end,
          lambda do |_, _, &block|
            b_called = true
            block.call
          end
        ]
        stack = described_class.new(middleware)
        stack.run(double)

        expect(a_called && b_called).to eq false
      end

      it 'calls a passed block at the end of the chain' do
        a_called = false
        b_called = false

        middleware = [
          lambda do |_, _, &block|
            a_called = true
            block.call
          end
        ]
        stack = described_class.new(middleware)
        stack.run(double) { b_called = true }

        expect(a_called && b_called).to eq true
      end
    end
  end

  describe Handler do
    subject(:handler) { described_class.new(double(:run), double) }

    describe '#matches?' do
      it 'always returns true' do
        expect(handler.matches?(double)).to eq true
      end
    end

    describe '#after_call' do
      it 'does nothing' do
        expect(handler.after_call(double)).to be_falsey
      end
    end

    describe '#call' do
      it 'runs the contained stack' do
        stack = double(:run)
        proc = proc {}
        event = double

        handler = described_class.new(stack, proc)
        expect(stack).to receive(:run).with(event) do |_event, &block|
          expect(block).to be(proc)
        end
        handler.call(event)
      end
    end
  end

  describe HandlerMiddleware do
    describe '#call' do
      it 'yields with a matching event' do
        handler = double
        event = double
        allow(handler).to receive(:matches?).with(event).and_return(true)
        called = false

        middleware = described_class.new(handler)
        middleware.call(event, nil) do
          called = true
        end
        expect(called).to eq true
      end

      it "doesn't yield with a non-matching event" do
        handler = double
        event = double
        allow(handler).to receive(:matches?).with(event).and_return(false)
        called = false

        middleware = described_class.new(handler)
        middleware.call(event, nil) do
          called = true
        end
        expect(called).to eq false
      end
    end
  end

  describe Stock do
    let(:middlewares) { Stock.instance_variable_get('@middleware') }

    describe :message do
      describe :end_with do
        it 'matches String' do
          middleware = middlewares[:message][:end_with].call('!')
          good_event = double(content: 'foo!')
          bad_event = double(content: 'foo')
          expect(middleware.call(good_event, double, &-> { true })).to eq true
          expect(middleware.call(bad_event, double, &-> { true })).to eq nil
        end

        it 'matches String' do
          # BUG: Doesn't work without a group
          middleware = middlewares[:message][:end_with].call(/(\!$)/)
          good_event = double(content: 'foo!')
          bad_event = double(content: 'foo')
          expect(middleware.call(good_event, double, &-> { true })).to eq true
          expect(middleware.call(bad_event, double, &-> { true })).to eq nil
        end
      end

      describe :contains do
        it 'matches String' do
          middleware = middlewares[:message][:contains].call('bar')
          good_event = double(content: 'bar')
          bad_event = double(content: 'foo')
          expect(middleware.call(good_event, double, &-> { true })).to eq true
          expect(middleware.call(bad_event, double, &-> { true })).to eq nil
        end

        it 'matches Regexp' do
          # BUG: Doesn't work without a group
          middleware = middlewares[:message][:contains].call(/foo/)
          good_event = double(content: 'foo')
          bad_event = double(content: 'bar')
          expect(middleware.call(good_event, double, &-> { true })).to eq true
          expect(middleware.call(bad_event, double, &-> { true })).to eq nil
        end
      end

      describe :from do
        it 'matches String by name' do
          middleware = middlewares[:message][:from].call('z64')
          good_event = double(author: double(name: 'z64'))
          bad_event = double(author: double(name: 'raelys'))
          expect(middleware.call(good_event, double, &-> { true })).to eq true
          expect(middleware.call(bad_event, double, &-> { true })).to eq nil
        end

        it 'matches Integer by id' do
          middleware = middlewares[:message][:from].call(123)
          good_event = double(author: double(id: 123))
          bad_event = double(author: double(id: 456))
          expect(middleware.call(good_event, double, &-> { true })).to eq true
          expect(middleware.call(bad_event, double, &-> { true })).to eq nil
        end

        it 'matches :bot with current_bot' do
          middleware = middlewares[:message][:from].call(:bot)
          good_event = double(author: double(current_bot?: true))
          bad_event = double(author: double(current_bot?: false))
          expect(middleware.call(good_event, double, &-> { true })).to eq true
          expect(middleware.call(bad_event, double, &-> { true })).to eq nil
        end
      end

      describe :start_with do
        context 'with a String' do
          it 'matches with String#start_with' do
            middleware = middlewares[:message][:start_with].call('!')
            good_event = double(content: '!foo')
            bad_event = double(content: 'foo')
            expect(middleware.call(good_event, double, &-> { true })).to eq true
            expect(middleware.call(bad_event, double, &-> { true })).to eq nil
          end
        end

        context 'with a Regexp' do
          it 'matches with a regex' do
            middleware = middlewares[:message][:start_with].call(/\!/)
            good_event = double(content: '!foo')
            bad_event = double(content: 'foo')
            expect(middleware.call(good_event, double, &-> { true })).to eq true
            expect(middleware.call(bad_event, double, &-> { true })).to eq nil
          end
        end
      end

      describe :content do
        it 'matches on exact content' do
          middleware = middlewares[:message][:content].call('foo')
          good_event = double(content: 'foo')
          bad_event = double(content: 'bar')
          expect(middleware.call(good_event, double, &-> { true })).to eq true
          expect(middleware.call(bad_event, double, &-> { true })).to eq nil
        end
      end

      describe :in do
        it 'matches String with channel name' do
          middleware = middlewares[:message][:in].call('foo')
          good_event = double(channel: double(name: 'foo'))
          bad_event = double(channel: double(name: 'bar'))
          expect(middleware.call(good_event, double, &-> { true })).to eq true
          expect(middleware.call(bad_event, double, &-> { true })).to eq nil
        end

        it 'matches Integer with channel ID' do
          middleware = middlewares[:message][:in].call(123)
          good_event = double(channel: double(id: 123))
          bad_event = double(channel: double(id: 456))
          expect(middleware.call(good_event, double, &-> { true })).to eq true
          expect(middleware.call(bad_event, double, &-> { true })).to eq nil
        end
      end

      describe :after do
        it 'matches after the event timestamp' do
          middleware = middlewares[:message][:after].call(1)
          good_event = double(timestamp: 2)
          bad_event = double(timestamp: 0)
          expect(middleware.call(good_event, double, &-> { true })).to eq true
          expect(middleware.call(bad_event, double, &-> { true })).to eq nil
        end
      end

      describe :before do
        it 'matches before the event timestamp' do
          middleware = middlewares[:message][:before].call(1)
          good_event = double(timestamp: 0)
          bad_event = double(timestamp: 2)
          expect(middleware.call(good_event, double, &-> { true })).to eq true
          expect(middleware.call(bad_event, double, &-> { true })).to eq nil
        end
      end

      describe :private do
        it 'matches in private channels' do
          middleware = middlewares[:message][:private].call(true)
          good_event = double(channel: double(private?: true))
          bad_event = double(channel: double(private?: false))
          expect(middleware.call(good_event, double, &-> { true })).to eq true
          expect(middleware.call(bad_event, double, &-> { true })).to eq nil
        end
      end
    end
  end
end
