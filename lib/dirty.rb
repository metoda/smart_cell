module Celluloid
  class Task
    alias_method :old_suspend, :suspend
    alias_method :old_resume, :resume

    def suspend(*args, &blk)
      SmartCell::Tracker.down
      send(:old_suspend, *args, &blk)
    end

    def resume(*args, &blk)
      SmartCell::Tracker.up
      send(:old_resume, *args, &blk)
    end
  end
end
