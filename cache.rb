require 'dalli'
require 'rack-cache'
module Cache
  if ENV["MEMCACHEDCLOUD_SERVERS"]
    cache = Dalli::Client.new(ENV["MEMCACHEDCLOUD_SERVERS"].split(","),
                              {:username => ENV["MEMCACHEDCLOUD_USERNAME"],
                               :password => ENV["MEMCACHEDCLOUD_PASSWORD"],
                               :failover => true,
                               :socket_timeout => 1.5,
                               :socket_failure_delay => 0.2
    })
    use Rack::Cache,
      verbose: true,
      metastore:   cache,
      entitystore: cache
  end
end
