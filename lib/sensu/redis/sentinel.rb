require "sensu/redis/client"
require "sensu/redis/utilities"
require "eventmachine"

module Sensu
  module Redis
    class Sentinel
      attr_accessor :logger

      # Initialize the Sentinel connections. The default Redis master
      # name is "mymaster", which is the same name that the Sensu HA
      # Redis documentation uses. The master name must be set
      # correctly in order for `resolve()`.
      #
      # @param options [Hash] containing the standard Redis
      #   connection settings.
      def initialize(options={})
        @master = options[:master_group] || options[:master] || "mymaster"
        @sentinels = []
        connect_to_sentinels(options[:sentinels])
      end

      # Connect to a Sentinel instance and add the connection to
      # `@sentinels` to be called upon. This method defaults the
      # Sentinel host and port if either have not been set.
      #
      # @param options [Hash] containing the host and port.
      def connect_to_sentinel(options={})
        options[:host] ||= "127.0.0.1"
        options[:port] ||= 26379
        resolve_host(options[:host]) do |ip_address|
          if ip_address.nil?
            EM::Timer.new(1) do
              connect_to_sentinel(options)
            end
          else
            @sentinels << EM.connect(ip_address, options[:port].to_i, Client, options)
          end
        end
      end

      # Connect to all Sentinel instances. The Sentinel instance
      # connections will be added to `@sentinels`.
      #
      # @param sentinels [Array]
      def connect_to_sentinels(sentinels)
        sentinels.each do |options|
          connect_to_sentinel(options)
        end
      end

      # Select a Sentinel connection object that is currently
      # connected.
      #
      # @return [Object] Sentinel connection.
      def select_a_sentinel
        @sentinels.select { |sentinel| sentinel.connected? }.shuffle.first
      end

      # Retry `resolve()` with the provided callback.
      #
      # @yield callback called when Sentinel resolves the current
      #   Redis master address (host & port).
      def retry_resolve(&block)
        EM::Timer.new(1) do
          resolve(&block)
        end
      end

      # Create a Sentinel master resolve timeout, causing the previous
      # attempt to fail/cancel, while beginning another attempt.
      #
      # @param sentinel [Object] connection.
      # @param seconds [Integer] before timeout.
      # @yield callback called when Sentinel resolves the current
      #   Redis master address (host & port).
      def create_resolve_timeout(sentinel, seconds, &block)
        EM::Timer.new(seconds) do
          sentinel.fail
          sentinel.succeed
          retry_resolve(&block)
        end
      end

      # Resolve the current Redis master via Sentinel. The correct
      # Redis master name is required for this method to work.
      #
      # @yield callback called when Sentinel resolves the current
      #   Redis master address (host & port).
      def resolve(&block)
        sentinel = select_a_sentinel
        if sentinel.nil?
          if @logger
            @logger.debug("unable to determine redis master", {
              :reason => "not connected to a redis sentinel"
            })
            @logger.debug("retrying redis master resolution via redis sentinel")
          end
          retry_resolve(&block)
        else
          timeout = create_resolve_timeout(sentinel, 10, &block)
          sentinel.redis_command("sentinel", "get-master-addr-by-name", @master) do |host, port|
            timeout.cancel
            if host && port
              @logger.debug("redis master resolved via redis sentinel", {
                :host => host,
                :port => port.to_i
              }) if @logger
              block.call(host, port.to_i)
            else
              if @logger
                @logger.debug("unable to determine redis master", {
                  :reason => "redis sentinel did not return a redis master host and port"
                })
                @logger.debug("retrying redis master resolution via redis sentinel")
              end
              retry_resolve(&block)
            end
          end
        end
      end
    end
  end
end
