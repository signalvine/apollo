require 'bunny'
require 'json'

module Apollo
  module Rabbitmq
    class Listener
      # Returns a new listener. It listens on a randomly named queue bound to the specified exchange with the specified
      # routing key
      # @param exchange [String] the exchange to bind the queue to
      # @param key [String] the routing key to bind the queue to the exchange
      # @param opts [Hash]
      # @option opts [String] :rmq_username The username to connect to the rabbitmq server
      # @option opts [String] :rmq_password The password to connect to the rabbitmq server
      # @option opts [String] :address the hostname or ip to connect to the rabbitmq server
      # @option opts [Integer] :port the port to connect to the rabbitmq server
      def initialize(exchange, key, opts = {})
        username = CGI.escape opts.fetch(:rmq_username, 'guest')
        password = CGI.escape opts.fetch(:rmq_password, 'guest')
        host = opts.fetch(:ip, opts.fetch(:hostname, '127.0.0.1'))
        port = opts.fetch(:port, 5672)
        @conn = Bunny.new("amqp://#{username}:#{password}@#{host}:#{port}")
        @conn.start
        raise 'connection is nil' if @conn.nil?
        @ch = @conn.create_channel
        x = @ch.direct exchange
        @messages = []
        @ch.temporary_queue.bind(x, :routing_key => key).subscribe do |delivery_info, metadata, payload|
          @messages << JSON.parse(payload)
        end
      end

      # get_all returns all of the messages that were collected from the queue
      # @return [Array] An array of hashes from the json
      def get_all()
        @conn.close
        @messages
      end
    end
  end
end
