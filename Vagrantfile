Vagrant.configure(2) do |config|
  # Using a 32 bit box so that everyone can run the tests
  config.vm.box = "hashicorp/precise32"

  # Force vagrant to use virtualbox as there is only a virtualbox image for hashicorp/precise32
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.cpus = 1
  end

  # Disable the random key generation so that we can connect in the test suite
  config.ssh.insert_key = false

  config.vm.network "private_network", ip: "192.168.100.4"

  config.vm.provision 'ansible' do |ansible|
    ansible.playbook = 'test_vm.yml'
  end
end
