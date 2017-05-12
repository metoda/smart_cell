module SmartCell
  module Tracker
    extend self

    MUTEX = Mutex.new

    def store
      @store ||= {}
    end

    def safe_lock
      if MUTEX.owned?
        yield
      else
        MUTEX.synchronize do
          yield
        end
      end
    end

    def tick!
      safe_lock do
        @last_tick = Time.now.to_f
      end
    end

    def median(array)
      sorted = array.sort
      len = sorted.length
      (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
    end

    def diff
      total, result = safe_lock do
        finished = store.reduce([]) do |acc, (id, data)|
          next acc unless data.key?(:end)
          acc << id
        end
        t = Time.now.to_f - @last_tick.to_f
        tick!
        next [t, finished.map { |id| store.delete(id) }]
      end
      cpu_time = result.map do |data|
        data[:end] - data[:start] - data[:io]
      end
      cpu =
        if cpu_time.empty?
          nil
        else
          [cpu_time.reduce(0.0, &:+) / cpu_time.size, median(cpu_time)].max
        end
      return [
        cpu_time.size,
        total,
        cpu
      ]
    end

    def add(id, resumed_at)
      safe_lock do
        suspended_at = store[id].delete(:tick) || Time.now.to_f
        store[id][:io] += resumed_at - suspended_at
      end
    end

    def register
      store[Thread.current.object_id] = {start: Time.now.to_f, io: 0.0}
    end

    def finish
      store[Thread.current.object_id][:end] = Time.now.to_f
    end

    def down
      id = Thread.current.object_id
      return unless store.key?(id)
      store[id][:tick] ||= Time.now.to_f
    end

    def up
      id = Thread.current.object_id
      return unless store.key?(id)
      add(id, Time.now.to_f)
    end
  end
end
