module SmartCell
  class Worker
    include Celluloid::IO

    def run(processor, work)
      Tracker.register
      processor.run(work)
      Tracker.finish
      terminate
    end
  end
end
