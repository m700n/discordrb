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
end
