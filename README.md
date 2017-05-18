# SmartCell

A scheduling middleware for optimizing workload by using evented IO in
Celluloid.

## Basics

To use the SmartCell you have to create two separate pieces of interface,
the first is the scheduling. SmartCell will ask the scheduler (more
precisely the *run* method of the scheduler) for more work.

When SmartCell found work (a not nil value), it will do internal stuff and
execute the processing interface with the work it has (again more precisely
the *run* method of the processing).

Now for SmartCell to actually have any effect, you need a Celluloid::IO
compatible gem for whatever you are doing, *http.rb* for web requests,
and there are many more for most major database distributions.

## Example

The setup for making http requests

```ruby
  require "smart_cell"
  require "http"
```

Add basic scheduling that offers "work". This should be a queue of sorts in
your productive code, one that is thread-safe across processes.

For our example it is sufficient to rotate the urls that we want to request.

Note: *having this as a module or class or instance makes no difference!*

```ruby
  module MyQueue
    URLS = %w(
      https://www.amazon.com
      https://www.google.de
      https://www.google.com
      https://www.amazon.de
    )

    def self.run
      URLS[rand(URLS.size)]
    end
  end
```

The processing is a little more complex, but in essence your code goes there,
and it needs to use the Celluloid::IO or it won't work.

The *run* method receives the work that SmartCell receives from the scheduling.

Essentially you can spawn all kinds of threads, fibers, actors and whatnot
from the *run* method, it is however important for SmartCell, that the
*run* method only returns when all actors and threads which are using
Celluloid::IO are done.

```ruby
  module HttpRequester
    def self.run(url)
      HTTP.follow.get(url, socket_class: Celluloid::IO::TCPSocket,
        ssl_socket_class: Celluloid::IO::SSLSocket).to_s
    rescue => e
      puts e.message
    end
  end
```

Using SmartCell is quite easy in the end. Enabling debug will make you see
some output about finished dispatched, the timing and the estimates on
how much SmartCell thinks it can run in the next segment.

```ruby
  Celluloid.shutdown_timeout = 1
  t = Time.new
  SmartCell.dispatch(HttpRequester, MyQueue, debug: true)
  sleep 300
  puts Time.new.to_f - t.to_f
  Celluloid.shutdown
```

## Configuration

Config options can be handed to the dispatch.

```ruby
  SmartCell.dispatch(HttpRequester, MyQueue, tick_len: 15, debug: false)
```

### Tick length

The default for *tick_len* is 5 (seconds).

This is the time frame in which SmartCell waits for the work to complete.
At the beginning of the tick_len it creates new work (if available) and
at the end it uses the results to guess how much it can create in the next
tick_len.

Adjust this to a high enough value that your business logic can complete within
the time on average. In our example we assume a web request can finish within
the 5s margin.

### Base work amount

The default for *base_amount* is 15.

With this you control how much work is being spawned when nothing has finished
in the previous segment.

Set this value to as low as the minimum amount of work should be that it
should create every *tick_len* seconds.

### Maximum workers per second

The default for *max_workers_sec* is 50.

No matter how high SmartCell determines your capacity, this is how you cap it
down. When doing http requests, there is only so much you should do per
second. The maximum capacity cap is of course dependent on *tick_len*.
Multiply *max_workers_sec* with *tick_len* to get the total amount of work
being created per segment, never more.

# License

BSD-2 (see LICENSE file)
