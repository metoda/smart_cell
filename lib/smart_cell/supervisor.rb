module SmartCell
  class Supervisor
    include Celluloid

    TICK_LEN = 5
    THRESHOLD = 0.7
    MULTIPLIER = 10
    MAX_WORKERS_SEC = 50
    DEBUG = false

    def initialize(processor, scheduler, opts = {})
      if !processor.respond_to?(:run) || processor.method(:run).arity != 1
        raise ArgumentError.new("processor has no run(1) method")
      end
      if !scheduler.respond_to?(:run)
        raise ArgumentError.new("scheduler has no run(0) method")
      end
      configure(opts)

      @scheduler = scheduler
      @processor = processor

      Tracker.tick!
      every(@tick_len) { run }
    end

    def configure(opts)
      @tick_len = opts.delete(:tick_len) || TICK_LEN
      @threshold = opts.delete(:threshold) || THRESHOLD
      @multiplier = opts.delete(:multiplier) || MULTIPLIER
      @max_workers_sec = opts.delete(:max_workers_sec) || MAX_WORKERS_SEC
      @debug = opts.delete(:debug) || DEBUG
    end

    def run
      return if @shutdown
      sum, total, cpu = Tracker.diff
      puts
      p [sum, total, cpu] if @debug
      new_count =
        if cpu.nil?
          (@threshold * @multiplier).to_i
        else
          capacity = (total / cpu).floor
          puts "capacity #{capacity}" if @debug
          [capacity, (@max_workers_sec * @tick_len).to_i].min
        end
      puts "scheduling new #{new_count}" if @debug
      count = new_count.times.reduce(0) do |acc, _i|
        new_work = @scheduler.run
        break acc if new_work.nil?
        Worker.new.async.run(@processor, new_work)
        next acc + 1
      end
      puts "started #{count}" if @debug
    end

    def shutdown
      @shutdown = true
    end
  end
end
