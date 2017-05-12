
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "aestasit/devops-ubuntu-14.04"
  config.vm.network :private_network, ip: "192.168.78.12"
  config.vm.hostname = "local-dashboard.rigadevday.lv"

  config.ssh.forward_agent = true

  config.vm.provider :virtualbox do |v, override|
    v.gui = false
    v.customize ["modifyvm", :id, "--memory", 500]
    v.customize ["modifyvm", :id, "--cpus", 1]
  end

  config.vm.provision "update-apt-package-lists", type: "shell", inline: 'sudo apt-get -y -q update', privileged: false
  config.vm.provision "install-sqlite", type: "shell", inline: 'sudo apt-get -y -q install sqlite3 libsqlite3-dev', privileged: false
  config.vm.provision "install-ruby", type: "shell", inline: 'sudo apt-get -y -q install ruby ruby-dev nodejs g++ bundler', privileged: false
  config.vm.provision "create-db-dir", type: "shell", inline: 'sudo mkdir -p /var/lib/sqlite', privileged: false
  config.vm.provision "create-db", type: "shell", inline: 'sudo touch /var/lib/sqlite/rigadevday.db', privileged: false
  config.vm.provision "create-empty-config", type: "shell", inline: 'sudo touch /etc/rigadevday.yml', privileged: false
  config.vm.provision "install-dashing", type: "shell", inline: 'sudo gem install dashing', privileged: false
  config.vm.provision "install-dependencies", type: "shell", inline: 'cd /vagrant/; bundle install', privileged: false

end
