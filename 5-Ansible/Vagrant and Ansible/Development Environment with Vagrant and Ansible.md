With vagrant-hostsupdater you don't have to update your hostsfile and you can just export all ports to your local machine. So instead of exposing singe 5 ports to weird numbers, you can just go to http://example.com, like to a real website.

`vagrant plugin install vagrant-hostsupdater`

```
Installing the 'vagrant-hostsupdater' plugin. This can take a few minutes...
Fetching: vagrant-hostsupdater-1.1.1.160.gem (100%)
Installed the plugin 'vagrant-hostsupdater (1.1.1.160)'!
```

andra@Andras-MacBook-Pro vagrant % mkdir app-vm
andra@Andras-MacBook-Pro vagrant % cd app-vm 
andra@andras-mbp app-vm % ls
Vagrantfile					provisioning					

andra@andras-mbp app-vm % cat Vagrantfile 

```
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.ssh.insert_key = false
  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end
  config.vm.provision :ansible do |ansible|
    ansible.playbook = "provisioning/playbook.yml"
  end

end
```

andra@andras-mbp app-vm % ls provisioning 
`group_vars	playbook.yml	roles`

andra@andras-mbp app-vm % cat  provisioning/group_vars/all
`locale: en_US.UTF-8`

andra@andras-mbp app-vm % cat  provisioning/roles/general/tasks/main.yml 
```
---

- name: "generate the server locale"
  locale_gen: name={{ locale }} state=present

- name: Update locale (ensure LANG=en_US.UTF-8)
  lineinfile: dest=/etc/default/locale regexp=^LANG line='LANG=en_US.UTF-8'
  tags:
    - set_locale

- name: Update locale (ensure LC_ALL is absent)
  lineinfile: dest=/etc/default/locale regexp=^LC_ALL state=absent
  tags:
    - set_locale
              

- name: reload locale
  raw: . /etc/default/locale

```

andra@andras-mbp app-vm % cat  provisioning/playbook.yml                
```
---

- hosts: all
  become: true
  roles:
    - general
```
