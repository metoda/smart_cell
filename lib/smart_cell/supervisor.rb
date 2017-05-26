module SmartCell
  class Supervisor
    include Celluloid

    TICK_LEN = 5
    BASE_AMOUNT = 15
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
      run
      every(@tick_len) { run }
    end

    def configure(opts)
      @tick_len = opts.delete(:tick_len) || TICK_LEN
      @base_amount = opts.delete(:base_amount) || BASE_AMOUNT
      @max_workers_sec = opts.delete(:max_workers_sec) || MAX_WORKERS_SEC
      @debug = opts.delete(:debug) || DEBUG
    end

    def run
      return if @shutdown
      sum, total, cpu = Tracker.diff
      puts if @debug
      p [sum, total, cpu] if @debug
      new_count =
        if cpu.nil?
          @base_amount
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
