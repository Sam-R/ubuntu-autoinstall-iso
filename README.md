# ubuntu-autoinstall-iso
Create a ubuntu server iso image with cloud-init autoinstall configuration using nolcoud

# usage

download, save or clone the `make-iso.sh` file in this repo.

set permissions using `chmod 775 make-iso.sh` and execute `./make-iso.sh`

The script will check for pre-requisite commands, download Ubuntu Server 20.04, copy in any `user-data` or `meta-data` files present in the same directory as the script and create a new ISO image prefixed with `autoinstall-`
