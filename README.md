# ubuntu-autoinstall-iso

This script creates a ubuntu server iso image with cloud-init autoinstall configuration (using nolcoud).

An example `user-data` file is included. You may want to customise this, in particular the passwords! For more information about the user data, see the cloud-init documentation https://cloudinit.readthedocs.io/en/latest/topics/examples.html

# usage

download, save or clone the `make-iso.sh` file from this repo.

set permissions using `chmod 775 make-iso.sh` and execute `./make-iso.sh`

Create or customise the `user-data` file with your desired settings for the auto-install. It's worth noting that passwords should be hased (but even hashed they they are not totally secure). Use:

`mkpasswd --method=SHA-512 --rounds=4096`

To generate a hashed password (on debian/ubuntu `mkpasswd` is installed with the `whois` package for some reason 🤷)

The script will check for pre-requisite commands, download Ubuntu Server 20.04, copy in any `user-data` or `meta-data` files present in the same directory as the script and create a new ISO image prefixed with `autoinstall-`

example username and password are both `ubuntu`
