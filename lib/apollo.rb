require "apollo/version"
require "yaml"
require 'rabbitmq_manager'

module Apollo
  class Cluster

    # Creates a new cluster
    #
    # @param opts [Hash].
    # @option opts [String] :filename The complete path to the inventory file ("#{Dir.pwd}/inventory.yml")
    # @return [Cluster]
    def initialize(opts = {})
      filename = opts.fetch(:filename, "#{Dir.pwd}/inventory.yml")
      inventory = YAML.load_file(filename)

      begin
        hosts = inventory.fetch('hosts')
        raise 'host list empty' if hosts.nil?
        @hosts = process_host_list hosts
      rescue NoMethodError
        raise 'host key not defined in inventory file'
      end
    end

    # Gets a host
    #
    # @param host [Symbol] The host to get
    # @return [Hash, nil] Either the host or nil if the host doesn't exist
    def get_host(host)
      @hosts[host]
    end

    # Connects to the rabbitmq admin port on the specified host and waits until the specified queue has no messags
    #
    # @param host [Symbol] The host that the queue is on
    # @param queue [String] The name of the queue to wait on
    #
    # @param opts [Hash]
    # @option opts [Float]      :sleep_duration The number of seconds (1) to wait between checking the queue
    # @option opts [Float, nil] :timeout The number of seconds (nil) to wait before throwing an exception
    # @option opts [String]     :vhost The vhost ('/') that the queue is in
    #
    # @raise [RuntimeError] when the host is not in the inventory or the timeout has been exceeded
    #
    # @return [void] Only returns when the queue is empty
    def wait_for_queue_drain(host, queue, opts = {})
      raise "host #{host} not configured in the inventory" if @hosts[host].nil?

      sleep_duration = opts.fetch(:sleep_duration, 1)
      timeout = opts.fetch(:timeout, nil)

      start = Time.now
      while check_queue_length(host, queue, opts) != 0
        if not timeout.nil? and (Time.now.to_f - start.to_f) > timeout
          raise 'wait_for_queue_drain exceeded timeout'
        end
        sleep sleep_duration
      end
    end

    # Connects to the rabbitmq admin port on the specified host and gets the number of messages waiting in the specified
    # queue
    # @param host [Symbol] The host of the rabbitmq server
    # @param queue [String] The queue to check
    #
    # @param opts [Hash]
    # @option opts [String] :vhost The vhost ('/') that the queue is in
    #
    # @return [Integer] The number of messages waiting in the specified queue
    def check_queue_length(host, queue, opts={})
      host = @hosts[host]
      vhost = opts.fetch(:vhost, '/')
      username = CGI.escape host.fetch('rmq_username', 'guest')
      password = CGI.escape host.fetch('rmq_password', 'guest')
      port = host.fetch('rmq_port', 15672)

      manager = RabbitMQManager.new "http://#{username}:#{password}@#{address host}:#{port}"
      manager.queue(vhost, queue)['messages']
    end

    private

    # Parses the inventory that gets read off of disk. It converts the keys to symbols.
    # @param host_list [Hash]
    # @return [Hash]
    # @raise [RuntimeError] when some required fields aren't specified
    def process_host_list(host_list)
      list = {}
      host_list.each do |key, value|
        raise "host #{key} is not addressable" if value['ip'].nil? and value['hostname'].nil?
        raise "host #{key} has an invalid rmq_port #{value['rmq_port']}" unless value['rmq_port'].nil? or value['rmq_port'].is_a? Numeric
        list[key.to_sym] = value
      end
      list
    end

    # Gets the specified host's proper addressing
    # @param host [Hash] The host that we want to address
    # @return [String] The address to connect to the host on
    def address(host)
      unless host['ip'].nil?
        host['ip']
      else
        host['hostname']
      end
    end
  end
end
