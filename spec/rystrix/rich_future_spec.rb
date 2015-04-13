require 'spec_helper'

describe Rystrix::RichFuture do
  describe '#get' do
    context 'with success' do
      it 'should return normal value' do
        future = Rystrix::RichFuture.new do
          42
        end
        future.execute
        expect(future.get).to eq(42)
      end
    end

    context 'with failure' do
      it 'should raise exception' do
        future = Rystrix::RichFuture.new do
          raise RuntimeError
        end
        future.execute
        expect { future.get }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#get_or_else' do
    context 'with success' do
      it 'should return normal value' do
        future = Rystrix::RichFuture.new do
          42
        end
        future.execute
        expect(future.get_or_else { 0 }).to eq(42)
      end
    end

    context 'with recover' do
      it 'should raise exception' do
        future = Rystrix::RichFuture.new do
          raise RuntimeError
        end
        future.execute
        expect(future.get_or_else { 0 }).to eq(0)
      end
    end

    context 'with also failure' do
      it 'should raise exception' do
        future = Rystrix::RichFuture.new do
          raise RuntimeError
        end
        future.execute
        expect { future.get_or_else { raise Exception } }.to raise_error(Exception)
      end
    end
  end

  describe '#fail' do
    it 'should fail immediately' do
      future = Rystrix::RichFuture.new do
        sleep 1000
        42
      end
      future.execute
      future.fail(Exception.new)
      expect(future.completed?).to be true
      expect(future.rejected?).to be true
      expect(future.reason).to be_instance_of(Exception)
    end

    it 'should notify to observer' do
      future = Rystrix::RichFuture.new do
        sleep 1000
        42
      end
      reason = nil
      future.add_observer do |_, _, r|
        reason = r
      end
      future.fail(RuntimeError.new)
      expect(reason).to be_instance_of(RuntimeError)
    end
  end

  describe '#executed?' do
    context 'with executed' do
      it 'should be true' do
        future = Rystrix::RichFuture.new do
          42
        end
        future.execute
        expect(future.executed?).to be true
      end
    end

    context 'with not executed' do
      it 'should be false' do
        future = Rystrix::RichFuture.new do
          42
        end
        expect(future.executed?).to be false
      end
    end
  end

  describe '#execute' do
    context 'with thread pool overflow' do
      it 'should throw RejectedExecutionError' do
        executor = Concurrent::ThreadPoolExecutor.new(
          min_threads: 1,
          max_threads: 1,
          max_queue: 1,
        )
        future1 = Rystrix::RichFuture.new(executor: executor) do
          42
        end
        future2 = Rystrix::RichFuture.new(executor: executor) do
          42
        end
        future1.execute
        expect { future2.execute }.to raise_error(Rystrix::RejectedExecutionError)
      end
    end
  end

  describe '#safe_execute' do
    context 'with thread pool overflow' do
      it 'should not throw RejectedExecutionError' do
        executor = Concurrent::ThreadPoolExecutor.new(
          min_threads: 10,
          max_threads: 10,
          max_queue: 50,
        )
        futures = 1000.times.map do
          Rystrix::RichFuture.new(executor: executor) do
            42
          end
        end
        futures.each(&:safe_execute)
        futures.each(&:wait)
        expect(futures.first.get).to eq(42)
        expect { futures.last.get }.to raise_error(Rystrix::RejectedExecutionError)
      end
    end
  end
end
