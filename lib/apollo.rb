require "apollo/version"
require "yaml"
require 'rabbitmq_manager'

module Apollo
  class Cluster

    # Creates a new cluster
    # opts - The Hash of options (default: {})
    #   :filename - The complete path to the inventory
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

    def get_host(host)
      @hosts[host]
    end

    # Connects to the rabbitmq admin port on the specified host and waits until the specified queue has no messags
    # opts - The hash of options (default: {})
    #   :sleep_duration - the time to wait between checking the queue (default: 1)
    #   :timeout - the maximum amount of time before giving up (default: nil)
    #   :vhost - the rabbitmq vhost that the queue is on (default: '/')
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
    # opts - The hash of options (default: {})
    #   :vhost - the rabbitmq vhost that the queue is on (default: '/')
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

    def process_host_list(host_list)
      list = {}
      host_list.each do |key, value|
        raise "host #{key} is not addressable" if value['ip'].nil? and value['hostname'].nil?
        raise "host #{key} has an invalid rmq_port #{value['rmq_port']}" unless value['rmq_port'].nil? or value['rmq_port'].is_a? Numeric
        list[key.to_sym] = value
      end
      list
    end

    def address(host)
      unless host['ip'].nil?
        host['ip']
      else
        host['hostname']
      end
    end
  end
end
