# -*- mode: ruby -*-
# vim: set ft=ruby :

#ENV['VAGRANT_SERVER_URL'] = 'https://vagrant.elab.pro'

MACHINES = {
  :lvm1 => {
        :box_name => "centos-7-1804",
		:vm_name => "vmlvm",
        #:ip_a ddr => '192.168.8.9',
		:net => [
           ["192.168.8.2", 2, "255.255.255.0", "mynet"],
		:box_version => "1804.02",
        ],
	:disks => {
		:sata1 => {
			:dfile => './sata1.vdi',
			:size => 10240,
			:port => 1
		},
		:sata2 => {
                        :dfile => './sata2.vdi',
                        :size => 2048, # Megabytes
			:port => 2
		},
                :sata3 => {
                        :dfile => './sata3.vdi',
                        :size => 1024,
                        :port => 3
                },
                :sata4 => {
                        :dfile => './sata4.vdi',
                        :size => 1024, # Megabytes
                        :port => 4
                },
				   

	}

		
  },
}

Vagrant.configure("2") do |config|

  MACHINES.each do |boxname, boxconfig|
		config.vm.synced_folder "sync/", "/vagrant", type: "rsync", create: "true"
      config.vm.define boxname do |box|

          box.vm.box = boxconfig[:box_name]
          box.vm.host_name = boxname.to_s

          #box.vm.network "forwarded_port", guest: 3260, host: 3260+offset

          #box.vm.network "private_network", ip: boxconfig[:ip_addr]
		        boxconfig[:net].each do |ipconf|
        box.vm.network("private_network", ip: ipconf[0], adapter: ipconf[1], netmask: ipconf[2], virtualbox__intnet: ipconf[3])

      end
		  

          box.vm.provider :virtualbox do |vb|
            	  vb.customize ["modifyvm", :id, "--memory", "1024"]
				  vb.name = boxconfig[:vm_name]
                  needsController = false
		  boxconfig[:disks].each do |dname, dconf|
			  unless File.exist?(dconf[:dfile])
				vb.customize ['createhd', '--filename', dconf[:dfile], '--variant', 'Fixed', '--size', dconf[:size]]
                                needsController =  true
                          end

		  end
                  if needsController == true
                     vb.customize ["storagectl", :id, "--name", "SATA", "--add", "sata" ]
                     boxconfig[:disks].each do |dname, dconf|
                         vb.customize ['storageattach', :id,  '--storagectl', 'SATA', '--port', dconf[:port], '--device', 0, '--type', 'hdd', '--medium', dconf[:dfile]]
                     end
                  end
          end


		#box.vm.provision "shell", path: "dz_lvm.sh", name: "dz"
		#box.vm.provision "shell", path: "dz_lvm.sh", name: "dz1"

      end
  end
end
