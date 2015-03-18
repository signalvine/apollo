require "apollo/version"
require "yaml"

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

    private

    def process_host_list(host_list)
      list = {}
      host_list.each do |key, value|
        list[key.to_sym] = value
      end
      list
    end
  end
end
