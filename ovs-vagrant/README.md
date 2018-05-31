# OVS-Docker-CentOS7 Vagrantfile
This Vagrantfile sets up Open vSwitch and Docker on a CentOS host for
Amazon AWS EC2 instance. Use this for testing purposes only.

## Dependency Information
* CentOS 7
* Vagrant 2.0.3
* Ruby 2.5.0
* Bundler 1.16.1

## Vagrant Box Information
See `test_box.rb` for versioning information.

## Usage
For more information about Vagrant usage, see 
[Vagrant's documentation](https://www.vagrantup.com/docs/)
* Download Vagrantfile to a directory, navigate to inside
the directory
* Download the bootstrap shell script, the Vagrantfile
needs it to provision Open vSwitch and other components.
* Run the box.
* To SSH into the box, use `$ vagrant ssh`.
* To destroy the box, use `$ vagrant destroy`.

## Test
There are tests under `test_box.rb` that check if the box conforms to
versioning expected. They should be run separately.

### Pre-Requisites
* Ruby
* Bundler
* Inspec

### Run
1. Install the required gems.
    ```
    bundle install
    ```
2. Run Inspec to run the tests.
    ```
    inspec exec test_box.rb -t ssh://vagrant@127.0.0.1:2222 -i $(vagrant ssh-config | grep -m 1 IdentityFile | cut -d ' ' -f 4)
    ```
