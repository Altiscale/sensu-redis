require File.join(File.dirname(__FILE__), "helpers")
require "sensu/redis"

describe "Sensu::Redis" do
  include Helpers

  it "can connect to a redis instance" do
    async_wrapper do
      Sensu::Redis.connect do |redis|
        redis.callback do
          expect(redis.connected?).to eq(true)
          async_done
        end
      end
    end
  end

  it "can connect to a redis instance with a hostname" do
    async_wrapper do
      Sensu::Redis.connect(:host => "localhost") do |redis|
        redis.callback do
          expect(redis.connected?).to eq(true)
          async_done
        end
      end
    end
  end

  it "can connect to a redis master via sentinel", :sentinel => true do
    async_wrapper do
      Sensu::Redis.connect(:sentinels => [{:port => 26379}]) do |redis|
        redis.callback do
          expect(redis.connected?).to eq(true)
          async_done
        end
      end
    end
  end

  it "can connect to a redis master via comma-separated sentinel URL string", :sentinel => true do
    async_wrapper do
      Sensu::Redis.connect(:sentinels => "redis://127.0.0.1:26379,redis://127.0.0.1:26379") do |redis|
        redis.callback do
          expect(redis.connected?).to eq(true)
          async_done
        end
      end
    end
  end

  it "can connect to a redis instance with TLS", :tls => true do
    async_wrapper do
      Sensu::Redis.connect(:port => 6380, :tls => {}) do |redis|
        redis.callback do
          expect(redis.connected?).to eq(true)
          async_done
        end
      end
    end
  end
end
