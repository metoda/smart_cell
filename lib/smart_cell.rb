require "celluloid/current"
require "celluloid/io"

require "dirty"
require "smart_cell/supervisor"
require "smart_cell/worker"
require "smart_cell/tracker"

module SmartCell
  extend self

  def dispatch(*args, &blk)
    Supervisor.new(*args, &blk)
  end
end
