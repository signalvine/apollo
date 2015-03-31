require "apollo/version"
require "yaml"
require 'net/ssh'
require 'rabbitmq_manager'
require 'apollo/rabbitmq'

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

    # create_rmq_listener creates an exclusive queue with a randomized name bound to the specified exchange with the
    # specified routing key
    # @param host [Symbol] the host that the queue is on
    # @param exchange [String] the exchange to bind the queue to
    # @param key [String] The routing key to use to bind the queue to the specified exchange
    # @return [Apollo::Rabbitmq::Listener] A listener listening on the specified queue
    def create_rmq_listener(host, exchange, key)
      sym_hash = Hash.new
      @hosts[host].each { |k, v| sym_hash[k.to_sym] = v}
      Apollo::Rabbitmq::Listener.new(exchange, key, sym_hash)
    end

    # Runs the specified command on the specified host
    #
    # @param on [Symbol] The host to run the command on
    # @param command [String] The command ('/bin/true') to run
    #
    # @param opts [Hash] Additional options for the ssh connection. For the complete list, see http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start
    # @option opts [bool] :forward_agent (true) whether to forward the current user's agent
    # @option opts [bool] :allow_unsuccessful (false) whether a non-zero exit call raises an exception or not
    #
    # @return [String]
    # @raises [RuntimeError] when the host
    def run(on, command = '/bin/true', opts= {})
      host = @hosts[on]
      raise "#{on} doesn't exist in the inventory" if host.nil?
      opts[:forward_agent] = opts.fetch(:forward_agent, true)

      output = ""
      rc = 0
      Net::SSH.start(address(host), host['user'], opts) do |ssh|
        chan = ssh.open_channel do |ch|
          ch.exec command do |ch, success|
            raise "#{command} didn't complete successfully" if not success and not opts.fetch(:allow_unsuccessful, false)
          end

          ch.on_data do |c, data|
            output += data
          end

          ch.on_extended_data do |c, type, data|
            output += data
          end

          ch.on_request "exit-status" do |ch, data|
            rc = data.read_long
          end
        end

        chan.wait
        raise "#{command} didn't complete successfully" unless rc == 0
        return output
      end
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
